import logging

import httpx
import numpy as np

from app.core.exceptions import EmbeddingError

logger = logging.getLogger(__name__)

_EMBEDDING_API_URL = (
    "https://generativelanguage.googleapis.com/v1beta/models/{model}:embedContent"
)


class EmbeddingService:
    """Generate embeddings using the Gemini embedding API."""

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

        vectors: list[list[float]] = []
        for text in texts:
            vectors.append(await self._embed_single(text))
        return np.array(vectors, dtype=np.float32)

    async def _embed_single(self, text: str) -> list[float]:
        url = _EMBEDDING_API_URL.format(model=self.model_name)
        payload = {
            "model": f"models/{self.model_name}",
            "content": {
                "parts": [{"text": text}],
            },
            "outputDimensionality": self.embedding_dim,
        }

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    url,
                    params={"key": self.api_key},
                    json=payload,
                )
                response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            detail = exc.response.text
            logger.error("Gemini API embedding failed: %s", detail)
            raise EmbeddingError(f"Embedding failed: {detail}") from exc
        except httpx.HTTPError as exc:
            logger.error("Gemini API embedding request failed: %s", exc)
            raise EmbeddingError(f"Embedding failed: {exc}") from exc

        data = response.json()
        try:
            return data["embedding"]["values"]
        except (KeyError, TypeError) as exc:
            logger.error("Unexpected Gemini embedding response: %s", data)
            raise EmbeddingError("Embedding failed: unexpected Gemini API response.") from exc

    async def embed_query(self, query: str) -> np.ndarray:
        result = await self.embed_texts([query])
        return result[0]
