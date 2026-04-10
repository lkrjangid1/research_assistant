import asyncio
import logging
import numpy as np
from app.core.exceptions import EmbeddingError

logger = logging.getLogger(__name__)

BATCH_SIZE = 250  # Vertex AI batch limit


class EmbeddingService:
    """Generate embeddings using Vertex AI text-embedding-004 (768-dim)."""

    def __init__(self, project_id: str, location: str, model_name: str = "text-embedding-004"):
        self.project_id = project_id
        self.location = location
        self.model_name = model_name
        self.embedding_dim = 768
        self._model = None

    def _get_model(self):
        if self._model is None:
            from google.cloud import aiplatform
            from vertexai.language_models import TextEmbeddingModel
            aiplatform.init(project=self.project_id, location=self.location)
            self._model = TextEmbeddingModel.from_pretrained(self.model_name)
        return self._model

    async def embed_texts(self, texts: list[str]) -> np.ndarray:
        """Embed a list of texts; returns shape (n, 768) float32."""
        try:
            return await asyncio.to_thread(self._embed_texts_sync, texts)
        except Exception as exc:
            logger.error("Embedding failed: %s", exc)
            raise EmbeddingError(f"Embedding failed: {exc}") from exc

    def _embed_texts_sync(self, texts: list[str]) -> np.ndarray:
        model = self._get_model()
        all_embeddings: list[list[float]] = []
        for i in range(0, len(texts), BATCH_SIZE):
            batch = texts[i : i + BATCH_SIZE]
            embeddings = model.get_embeddings(batch)
            all_embeddings.extend([e.values for e in embeddings])
        return np.array(all_embeddings, dtype=np.float32)

    async def embed_query(self, query: str) -> np.ndarray:
        """Embed a single query string; returns shape (768,) float32."""
        result = await self.embed_texts([query])
        return result[0]
