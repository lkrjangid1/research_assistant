import io
import pytest
import numpy as np
from pathlib import Path
from unittest.mock import AsyncMock, MagicMock
from fastapi.testclient import TestClient

from app.services.pdf_processor import PDFProcessor
from app.services.chunker import SemanticChunker
from app.services.vector_store import VectorStore


@pytest.fixture
def pdf_processor():
    return PDFProcessor()


@pytest.fixture
def chunker():
    return SemanticChunker()


@pytest.fixture
def vector_store(tmp_path):
    return VectorStore(embedding_dim=768, index_path=tmp_path / "test_index")


@pytest.fixture
def mock_embedding_service():
    svc = AsyncMock()
    svc.embed_texts = AsyncMock(
        side_effect=lambda texts: np.random.rand(len(texts), 768).astype(np.float32)
    )
    svc.embed_query = AsyncMock(
        return_value=np.random.rand(768).astype(np.float32)
    )
    return svc


@pytest.fixture
def mock_vertex_client():
    client = AsyncMock()
    client.generate = AsyncMock(
        return_value="The paper proposes a novel approach. [Test Paper, Page 1]"
    )
    return client


@pytest.fixture
def sample_pdf_bytes():
    """Create a minimal valid PDF using PyMuPDF."""
    import fitz
    doc = fitz.open()
    page = doc.new_page()
    page.insert_text((72, 72), "This is a test research paper about machine learning.\n\nAbstract: We propose a novel method.")
    page2 = doc.new_page()
    page2.insert_text((72, 72), "Introduction\n\nDeep learning has shown great promise in various tasks.")
    pdf_bytes = doc.tobytes()
    doc.close()
    return pdf_bytes


@pytest.fixture
def test_client():
    from main import app
    from app.api.dependencies import get_rag_service, get_summarizer_service, get_embedding_service, get_vertex_ai_client
    mock_rag = AsyncMock()
    from app.models.chat import RAGResponse, Citation
    mock_rag.query = AsyncMock(return_value=RAGResponse(
        text="Test answer [Test Paper, Page 1]",
        citations=[Citation(paper_title="Test Paper", page_number=1, excerpt="test excerpt")],
    ))
    mock_rag.execute_command = AsyncMock(return_value=RAGResponse(text="Summary here", citations=[]))
    app.dependency_overrides[get_rag_service] = lambda: mock_rag
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
