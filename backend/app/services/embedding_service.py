import asyncio
import logging
import time

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

_BATCH_SIZE = 100  # Gemini batchEmbedContents limit
_CONCURRENT_LIMIT = 25  # parallel requests for single-embed fallback


class EmbeddingService:
    """Generate embeddings via Gemini batch API with concurrent fallback."""

    def __init__(
        self,
        api_key: str,
        model_name: str = "gemini-embedding-001",
        embedding_dim: int = 768,
    ):
        self.api_key = api_key
        self.model_name = model_name
        self.embedding_dim = embedding_dim

    async def embed_texts(self, texts: list[str]) -> np.ndarray:
        if not self.api_key:
            raise EmbeddingError("Embedding failed: GEMINI_API_KEY is not configured.")
        if not texts:
            return np.empty((0, self.embedding_dim), dtype=np.float32)

        logger.info("Embedding %d texts (batch_size=%d, model=%s)", len(texts), _BATCH_SIZE, self.model_name)
        t_start = time.time()
        all_vectors: list[list[float]] = []

        async with httpx.AsyncClient(timeout=120.0) as client:
            for i in range(0, len(texts), _BATCH_SIZE):
                batch = texts[i : i + _BATCH_SIZE]
                t_batch = time.time()

                try:
                    batch_vectors = await self._embed_batch(client, batch)
                    all_vectors.extend(batch_vectors)
                    logger.info(
                        "  Batch %d-%d: %d embeddings via batchEmbedContents in %.1fs",
                        i, i + len(batch), len(batch), time.time() - t_batch,
                    )
                except EmbeddingError as exc:
                    logger.warning(
                        "  Batch %d-%d FAILED (%.1fs): %s — falling back to %d-way concurrent",
                        i, i + len(batch), time.time() - t_batch, exc, _CONCURRENT_LIMIT,
                    )
                    t_fallback = time.time()
                    fallback = await self._embed_concurrent(client, batch)
                    all_vectors.extend(fallback)
                    logger.info(
                        "  Concurrent fallback %d-%d: %d embeddings in %.1fs",
                        i, i + len(batch), len(batch), time.time() - t_fallback,
                    )

        logger.info("Embedding complete: %d vectors in %.1fs", len(all_vectors), time.time() - t_start)
        return np.array(all_vectors, dtype=np.float32)

    # ── Batch API (one HTTP call per ≤100 texts) ────────────────────────────

    async def _embed_batch(
        self, client: httpx.AsyncClient, texts: list[str]
    ) -> list[list[float]]:
        url = _BATCH_EMBED_URL.format(model=self.model_name)
        requests = [
            {
                "model": f"models/{self.model_name}",
                "content": {"parts": [{"text": t}]},
                "outputDimensionality": self.embedding_dim,
            }
            for t in texts
        ]

        try:
            response = await client.post(
                url, params={"key": self.api_key}, json={"requests": requests},
            )
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            detail = exc.response.text[:300]
            raise EmbeddingError(f"HTTP {exc.response.status_code}: {detail}") from exc
        except httpx.HTTPError as exc:
            raise EmbeddingError(str(exc)) from exc

        data = response.json()
        try:
            return [emb["values"] for emb in data["embeddings"]]
        except (KeyError, TypeError, IndexError) as exc:
            raise EmbeddingError(f"Unexpected response shape: {list(data.keys())}") from exc

    # ── Concurrent single-embed fallback ─────────────────────────────────────

    async def _embed_concurrent(
        self, client: httpx.AsyncClient, texts: list[str]
    ) -> list[list[float]]:
        sem = asyncio.Semaphore(_CONCURRENT_LIMIT)

        async def _one(text: str) -> list[float]:
            async with sem:
                return await self._embed_single(client, text)

        return list(await asyncio.gather(*[_one(t) for t in texts]))

    async def _embed_single(
        self, client: httpx.AsyncClient, text: str
    ) -> list[float]:
        url = _SINGLE_EMBED_URL.format(model=self.model_name)
        payload = {
            "model": f"models/{self.model_name}",
            "content": {"parts": [{"text": text}]},
            "outputDimensionality": self.embedding_dim,
        }

        try:
            response = await client.post(
                url, params={"key": self.api_key}, json=payload,
            )
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            detail = exc.response.text[:300]
            raise EmbeddingError(f"Embedding failed: HTTP {exc.response.status_code}: {detail}") from exc
        except httpx.HTTPError as exc:
            raise EmbeddingError(f"Embedding failed: {exc}") from exc

        data = response.json()
        try:
            return data["embedding"]["values"]
        except (KeyError, TypeError) as exc:
            raise EmbeddingError("Unexpected response shape") from exc

    # ── Query helper ─────────────────────────────────────────────────────────

    async def embed_query(self, query: str) -> np.ndarray:
        result = await self.embed_texts([query])
        return result[0]
