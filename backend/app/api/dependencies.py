from functools import lru_cache
from pathlib import Path

from app.config import get_settings
from app.models.paper import PaperStatus, ProcessingStatus
from app.services.pdf_processor import PDFProcessor
from app.services.chunker import SemanticChunker
from app.services.vertex_ai_client import VertexAIClient
from app.services.embedding_service import EmbeddingService
from app.services.vector_store import VectorStore
from app.services.rag_service import RAGService
from app.services.summarizer import SummarizerService

# ── Singleton factories ────────────────────────────────────────────────────────

@lru_cache
def get_pdf_processor() -> PDFProcessor:
    return PDFProcessor()


@lru_cache
def get_chunker() -> SemanticChunker:
    return SemanticChunker()


@lru_cache
def get_vertex_ai_client() -> VertexAIClient:
    settings = get_settings()
    return VertexAIClient(
        api_key=settings.gemini_api_key,
        model_name=settings.gemini_model,
    )


@lru_cache
def get_embedding_service() -> EmbeddingService:
    settings = get_settings()
    return EmbeddingService(
        api_key=settings.gemini_api_key,
        model_name=settings.embedding_model,
        embedding_dim=settings.embedding_dim,
        cache_path=Path(settings.embedding_cache_path),
    )


@lru_cache
def get_vector_store() -> VectorStore:
    settings = get_settings()
    return VectorStore(embedding_dim=settings.embedding_dim, index_path=settings.faiss_index_dir)


@lru_cache
def get_rag_service() -> RAGService:
    return RAGService(
        vector_store=get_vector_store(),
        embedding_service=get_embedding_service(),
        llm_client=get_vertex_ai_client(),
    )


@lru_cache
def get_summarizer_service() -> SummarizerService:
    return SummarizerService(llm_client=get_vertex_ai_client())


# ── In-memory paper status store ───────────────────────────────────────────────

_paper_status_store: dict[str, PaperStatus] = {}


def get_paper_status_store() -> dict[str, PaperStatus]:
    return _paper_status_store


def set_paper_status(paper_id: str, status: PaperStatus) -> None:
    _paper_status_store[paper_id] = status
