import asyncio
import hashlib
import logging
import pickle
import re
import time
from collections.abc import Awaitable, Callable
from pathlib import Path

import httpx
import numpy as np
from google.auth.credentials import Credentials

from app.core.exceptions import EmbeddingError
from app.services.vertex_auth import VertexAuth, VertexAuthError

logger = logging.getLogger(__name__)

_VERTEX_MODEL_PATH = (
    "projects/{project}/locations/{location}/publishers/google/models/{model}"
)
_VERTEX_PREDICT_URL = "https://{host}/v1/{model}:predict"

_BATCH_SIZE = 100
_CONCURRENT_LIMIT = 1
_REQUESTS_PER_MINUTE = 4
_MAX_RETRIES = 5
_MAX_RETRY_DELAY_SECONDS = 60.0

# Only the first _MAX_EMBED_CHARS are sent to the API.
# Full chunk text stays in FAISS metadata for RAG context.
_MAX_EMBED_CHARS = 1024

# ── Text preprocessing: strip tokens that cost money but add zero retrieval value
_STRIP_PATTERNS = [
    (re.compile(r"\[\d+(?:[,;\s]+\d+)*\]"), ""),       # citation markers [1], [2,3]
    (re.compile(r"https?://\S+"), ""),                   # URLs
    (re.compile(r"\S+@\S+\.\S+"), ""),                   # emails
    (re.compile(r"(?:Fig(?:ure)?|Table|Eq(?:uation)?)\s*\.?\s*\d+", re.I), ""),  # Fig. 3, Table 2
    (re.compile(r"\s+"), " "),                            # collapse whitespace
]


class _AsyncRateLimiter:
    def __init__(self, requests_per_minute: int):
        self._interval = 60.0 / requests_per_minute if requests_per_minute > 0 else 0.0
        self._next_at = 0.0
        self._lock = asyncio.Lock()

    async def wait(self) -> None:
        if self._interval <= 0:
            return

        async with self._lock:
            now = time.monotonic()
            if now < self._next_at:
                await asyncio.sleep(self._next_at - now)
                now = time.monotonic()
            self._next_at = now + self._interval

    @property
    def interval(self) -> float:
        return self._interval


def _preprocess(text: str) -> str:
    """Strip low-value tokens before sending to the embedding API."""
    text = text[:_MAX_EMBED_CHARS]
    for pattern, repl in _STRIP_PATTERNS:
        text = pattern.sub(repl, text)
    return text.strip()


class EmbeddingService:
    """Vertex AI embedding API with persistent cache and token-cost optimisations.

    Cost levers applied:
    1. Hash-based persistent cache — same text is NEVER re-embedded
    2. Text preprocessing — strips citations, URLs, figure refs (~10% fewer tokens)
    3. Input truncation — first 1024 chars per chunk only
    4. Task types — RETRIEVAL_DOCUMENT/RETRIEVAL_QUERY for better vectors
    5. Reduced output dim — 256 instead of 768
    6. Bounded concurrency — Vertex predict calls are parallelised per batch
    7. Request pacing — gemini-embedding-001 accepts one input per request and
       low default quotas can throttle bursts.
    """

    def __init__(
        self,
        project_id: str = "",
        location: str = "us-central1",
        model_name: str = "gemini-embedding-001",
        embedding_dim: int = 256,
        cache_path: Path | None = None,
        credentials: Credentials | None = None,
        credentials_path: str = "",
        concurrent_limit: int = _CONCURRENT_LIMIT,
        requests_per_minute: int = _REQUESTS_PER_MINUTE,
        max_retries: int = _MAX_RETRIES,
    ):
        self.location = location.strip() or "us-central1"
        self.model_name = model_name.strip()
        self.embedding_dim = embedding_dim
        self._auth = VertexAuth(project_id, credentials, credentials_path)
        self._concurrent_limit = max(1, concurrent_limit)
        self._rate_limiter = _AsyncRateLimiter(max(0, requests_per_minute))
        self._max_retries = max(0, max_retries)

        # ── Persistent cache ─────────────────────────────────────────────
        self._cache: dict[str, list[float]] = {}
        self._cache_path = cache_path
        self._hits = 0
        self._misses = 0
        if cache_path:
            self._load_cache()

    # ── Cache helpers ────────────────────────────────────────────────────

    def _cache_key(self, text: str, task_type: str) -> str:
        raw = f"{self.model_name}:{self.embedding_dim}:{task_type}:{text}"
        return hashlib.sha256(raw.encode()).hexdigest()[:20]

    def _load_cache(self) -> None:
        if self._cache_path and self._cache_path.exists():
            try:
                with open(self._cache_path, "rb") as f:
                    self._cache = pickle.load(f)
                logger.info("Embedding cache loaded: %d entries", len(self._cache))
            except Exception:
                logger.warning("Corrupt embedding cache — starting fresh")
                self._cache = {}

    def _save_cache(self) -> None:
        if not self._cache_path:
            return
        self._cache_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self._cache_path, "wb") as f:
            pickle.dump(self._cache, f)

    # ── Public API ───────────────────────────────────────────────────────

    async def embed_texts(
        self,
        texts: list[str],
        task_type: str = "RETRIEVAL_DOCUMENT",
        progress_callback: Callable[[int, int], Awaitable[None] | None] | None = None,
    ) -> np.ndarray:
        if not texts:
            return np.empty((0, self.embedding_dim), dtype=np.float32)

        t_start = time.time()
        processed = [_preprocess(t) for t in texts]

        # ── Split cached vs uncached ─────────────────────────────────────
        results: dict[int, list[float]] = {}
        uncached_texts: list[str] = []
        uncached_indices: list[int] = []

        for i, text in enumerate(processed):
            key = self._cache_key(text, task_type)
            cached = self._cache.get(key)
            if cached is not None:
                results[i] = cached
                self._hits += 1
            else:
                uncached_texts.append(text)
                uncached_indices.append(i)
                self._misses += 1

        # ── Call API only for uncached texts ─────────────────────────────
        cached_count = len(texts) - len(uncached_texts)
        if cached_count:
            await self._notify_progress(progress_callback, cached_count, len(texts))

        if uncached_texts:
            logger.info(
                "Embedding %d texts (%d cached, %d to embed, dim=%d, task=%s)",
                len(texts), cached_count,
                len(uncached_texts), self.embedding_dim, task_type,
            )
            new_vectors = await self._batch_embed_all(
                uncached_texts,
                task_type,
                progress_callback,
                completed_offset=cached_count,
                total=len(texts),
            )
            for idx, vec in zip(uncached_indices, new_vectors):
                key = self._cache_key(processed[idx], task_type)
                self._cache[key] = vec
                results[idx] = vec
            self._save_cache()
        else:
            logger.info("Embedding %d texts — all from cache (0 API calls)", len(texts))

        total = self._hits + self._misses
        logger.info(
            "Cache stats: %d hits / %d total (%.0f%% hit rate, %d entries) — %.2fs",
            self._hits, total,
            100 * self._hits / max(1, total),
            len(self._cache),
            time.time() - t_start,
        )

        ordered = [results[i] for i in range(len(processed))]
        return np.array(ordered, dtype=np.float32)

    async def embed_query(self, query: str) -> np.ndarray:
        result = await self.embed_texts([query], task_type="RETRIEVAL_QUERY")
        return result[0]

    # ── Vertex Prediction API (private) ──────────────────────────────────

    async def _batch_embed_all(
        self,
        texts: list[str],
        task_type: str,
        progress_callback: Callable[[int, int], Awaitable[None] | None] | None = None,
        completed_offset: int = 0,
        total: int | None = None,
    ) -> list[list[float]]:
        all_vectors: list[list[float]] = []
        total_count = total or len(texts)
        async with httpx.AsyncClient(timeout=120.0) as client:
            for i in range(0, len(texts), _BATCH_SIZE):
                batch = texts[i : i + _BATCH_SIZE]
                t_batch = time.time()
                try:
                    vecs = await self._embed_batch(
                        client,
                        batch,
                        task_type,
                        completed_offset=completed_offset + len(all_vectors),
                        total=total_count,
                        progress_callback=progress_callback,
                    )
                    all_vectors.extend(vecs)
                    logger.info(
                        "  Batch %d-%d: %d Vertex embeddings in %.1fs",
                        i, i + len(batch), len(batch), time.time() - t_batch,
                    )
                except EmbeddingError as exc:
                    logger.warning("  Batch %d-%d FAILED: %s", i, i + len(batch), exc)
                    raise
        return all_vectors

    async def _embed_batch(
        self,
        client: httpx.AsyncClient,
        texts: list[str],
        task_type: str,
        completed_offset: int = 0,
        total: int | None = None,
        progress_callback: Callable[[int, int], Awaitable[None] | None] | None = None,
    ) -> list[list[float]]:
        try:
            url = _VERTEX_PREDICT_URL.format(
                host=self._api_host(),
                model=await self._model_path(),
            )
            headers = await self._auth.headers()
        except VertexAuthError as exc:
            raise EmbeddingError(f"Embedding failed: {exc}") from exc

        sem = asyncio.Semaphore(self._concurrent_limit)
        done = 0

        async def _one(text: str) -> list[float]:
            nonlocal done
            async with sem:
                vector = await self._embed_single(client, url, headers, text, task_type)
                done += 1
                await self._notify_progress(
                    progress_callback,
                    completed_offset + done,
                    total or len(texts),
                )
                return vector

        return list(await asyncio.gather(*[_one(t) for t in texts]))

    async def _embed_single(
        self,
        client: httpx.AsyncClient,
        url: str,
        headers: dict[str, str],
        text: str,
        task_type: str,
    ) -> list[float]:
        payload = {
            "instances": [
                {
                    "content": text,
                    "task_type": task_type,
                }
            ],
            "parameters": {
                "autoTruncate": True,
                "outputDimensionality": self.embedding_dim,
            },
        }

        for attempt in range(self._max_retries + 1):
            try:
                await self._rate_limiter.wait()
                resp = await client.post(
                    url,
                    headers=headers,
                    json=payload,
                )
                resp.raise_for_status()
                break
            except httpx.HTTPStatusError as exc:
                if exc.response.status_code == 429 and attempt < self._max_retries:
                    delay = self._retry_delay_seconds(exc.response, attempt)
                    logger.warning(
                        "Vertex embedding quota throttled; retrying in %.1fs (%d/%d)",
                        delay, attempt + 1, self._max_retries,
                    )
                    await asyncio.sleep(delay)
                    continue
                raise EmbeddingError(f"HTTP {exc.response.status_code}: {exc.response.text[:300]}") from exc
            except httpx.HTTPError as exc:
                raise EmbeddingError(f"Embedding failed: {exc}") from exc

        data = resp.json()
        try:
            return data["predictions"][0]["embeddings"]["values"]
        except (KeyError, TypeError, IndexError) as exc:
            raise EmbeddingError("Unexpected Vertex AI prediction response shape") from exc

    async def _model_path(self) -> str:
        if self.model_name.startswith("projects/"):
            return self.model_name
        project = await self._auth.project()
        if self.model_name.startswith("publishers/"):
            return f"projects/{project}/locations/{self.location}/{self.model_name}"
        return _VERTEX_MODEL_PATH.format(
            project=project,
            location=self.location,
            model=self.model_name,
        )

    def _api_host(self) -> str:
        if self.location == "global":
            return "aiplatform.googleapis.com"
        return f"{self.location}-aiplatform.googleapis.com"

    def _retry_delay_seconds(self, response: httpx.Response, attempt: int) -> float:
        retry_after = response.headers.get("retry-after")
        if retry_after:
            try:
                return min(float(retry_after), _MAX_RETRY_DELAY_SECONDS)
            except ValueError:
                pass

        base_delay = self._rate_limiter.interval or 2.0
        return min(base_delay * (2 ** attempt), _MAX_RETRY_DELAY_SECONDS)

    async def _notify_progress(
        self,
        progress_callback: Callable[[int, int], Awaitable[None] | None] | None,
        completed: int,
        total: int,
    ) -> None:
        if not progress_callback:
            return

        result = progress_callback(completed, total)
        if result is not None:
            await result

    @property
    def estimated_seconds_per_uncached_embedding(self) -> float:
        return self._rate_limiter.interval
