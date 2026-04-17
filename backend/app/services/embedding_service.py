import asyncio
import hashlib
import logging
import pickle
import re
import time
from pathlib import Path

import httpx
import numpy as np

from app.core.exceptions import EmbeddingError

logger = logging.getLogger(__name__)

_BATCH_EMBED_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/{model}:batchEmbedContents"
)
_SINGLE_EMBED_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/{model}:embedContent"
)

_BATCH_SIZE = 100
_CONCURRENT_LIMIT = 25

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


def _preprocess(text: str) -> str:
    """Strip low-value tokens before sending to the embedding API."""
    text = text[:_MAX_EMBED_CHARS]
    for pattern, repl in _STRIP_PATTERNS:
        text = pattern.sub(repl, text)
    return text.strip()


class EmbeddingService:
    """Gemini embedding API with persistent cache and token-cost optimisations.

    Cost levers applied:
    1. Hash-based persistent cache — same text is NEVER re-embedded
    2. Text preprocessing — strips citations, URLs, figure refs (~10% fewer tokens)
    3. Input truncation — first 1024 chars per chunk only
    4. Task types — RETRIEVAL_DOCUMENT/RETRIEVAL_QUERY for better vectors
    5. Reduced output dim — 256 instead of 768
    6. Batch API — 1 HTTP call per 100 texts
    """

    def __init__(
        self,
        api_key: str,
        model_name: str = "gemini-embedding-001",
        embedding_dim: int = 256,
        cache_path: Path | None = None,
    ):
        self.api_key = api_key
        self.model_name = model_name
        self.embedding_dim = embedding_dim

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
    ) -> np.ndarray:
        if not self.api_key:
            raise EmbeddingError("Embedding failed: GEMINI_API_KEY is not configured.")
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
        if uncached_texts:
            logger.info(
                "Embedding %d texts (%d cached, %d to embed, dim=%d, task=%s)",
                len(texts), len(texts) - len(uncached_texts),
                len(uncached_texts), self.embedding_dim, task_type,
            )
            new_vectors = await self._batch_embed_all(uncached_texts, task_type)
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

    # ── Batch API (private) ──────────────────────────────────────────────

    async def _batch_embed_all(
        self, texts: list[str], task_type: str,
    ) -> list[list[float]]:
        all_vectors: list[list[float]] = []
        async with httpx.AsyncClient(timeout=120.0) as client:
            for i in range(0, len(texts), _BATCH_SIZE):
                batch = texts[i : i + _BATCH_SIZE]
                t_batch = time.time()
                try:
                    vecs = await self._embed_batch(client, batch, task_type)
                    all_vectors.extend(vecs)
                    logger.info(
                        "  Batch %d-%d: %d embeddings in %.1fs",
                        i, i + len(batch), len(batch), time.time() - t_batch,
                    )
                except EmbeddingError as exc:
                    logger.warning(
                        "  Batch %d-%d FAILED: %s — concurrent fallback",
                        i, i + len(batch), exc,
                    )
                    vecs = await self._embed_concurrent(client, batch, task_type)
                    all_vectors.extend(vecs)
        return all_vectors

    async def _embed_batch(
        self, client: httpx.AsyncClient, texts: list[str], task_type: str,
    ) -> list[list[float]]:
        url = _BATCH_EMBED_URL.format(model=self.model_name)
        requests = [
            {
                "model": f"models/{self.model_name}",
                "content": {"parts": [{"text": t}]},
                "taskType": task_type,
                "outputDimensionality": self.embedding_dim,
            }
            for t in texts
        ]
        try:
            resp = await client.post(url, params={"key": self.api_key}, json={"requests": requests})
            resp.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise EmbeddingError(f"HTTP {exc.response.status_code}: {exc.response.text[:300]}") from exc
        except httpx.HTTPError as exc:
            raise EmbeddingError(str(exc)) from exc

        data = resp.json()
        try:
            return [emb["values"] for emb in data["embeddings"]]
        except (KeyError, TypeError, IndexError) as exc:
            raise EmbeddingError(f"Unexpected response: {list(data.keys())}") from exc

    async def _embed_concurrent(
        self, client: httpx.AsyncClient, texts: list[str], task_type: str,
    ) -> list[list[float]]:
        sem = asyncio.Semaphore(_CONCURRENT_LIMIT)

        async def _one(text: str) -> list[float]:
            async with sem:
                return await self._embed_single(client, text, task_type)

        return list(await asyncio.gather(*[_one(t) for t in texts]))

    async def _embed_single(
        self, client: httpx.AsyncClient, text: str, task_type: str,
    ) -> list[float]:
        url = _SINGLE_EMBED_URL.format(model=self.model_name)
        payload = {
            "model": f"models/{self.model_name}",
            "content": {"parts": [{"text": text}]},
            "taskType": task_type,
            "outputDimensionality": self.embedding_dim,
        }
        try:
            resp = await client.post(url, params={"key": self.api_key}, json=payload)
            resp.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise EmbeddingError(f"HTTP {exc.response.status_code}: {exc.response.text[:300]}") from exc
        except httpx.HTTPError as exc:
            raise EmbeddingError(f"Embedding failed: {exc}") from exc

        data = resp.json()
        try:
            return data["embedding"]["values"]
        except (KeyError, TypeError) as exc:
            raise EmbeddingError("Unexpected response shape") from exc
