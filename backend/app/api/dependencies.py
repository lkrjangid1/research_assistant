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
        project_id=settings.vertex_project_id,
        location=settings.vertex_location,
        model_name=settings.gemini_model,
    )


@lru_cache
def get_embedding_service() -> EmbeddingService:
    settings = get_settings()
    return EmbeddingService(
        project_id=settings.vertex_project_id,
        location=settings.vertex_location,
        model_name=settings.embedding_model,
    )


@lru_cache
def get_vector_store() -> VectorStore:
    settings = get_settings()
    return VectorStore(embedding_dim=768, index_path=Path(settings.faiss_index_path))


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
