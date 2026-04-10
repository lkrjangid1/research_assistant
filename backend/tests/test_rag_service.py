import numpy as np
import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock
from app.services.rag_service import RAGService
from app.services.vector_store import VectorStore
from app.models.chunk import SearchResult


def make_rag(tmp_path, llm_response="Answer [TestPaper, Page 2]"):
    vs = VectorStore(embedding_dim=4, index_path=tmp_path / "idx")
    emb_svc = AsyncMock()
    emb_svc.embed_query = AsyncMock(return_value=np.ones(4, dtype=np.float32) / 2)
    emb_svc.embed_texts = AsyncMock(
        side_effect=lambda texts: np.random.rand(len(texts), 4).astype(np.float32)
    )
    llm = AsyncMock()
    llm.generate = AsyncMock(return_value=llm_response)
    return RAGService(vs, emb_svc, llm), vs, emb_svc, llm


def seed_store(vs: VectorStore):
    e = np.ones((2, 4), dtype=np.float32)
    vs.add_embeddings(e, ["p1_0", "p1_1"],
                      [{"paper_id": "p1", "page_number": 1, "text": "deep learning text"},
                       {"paper_id": "p1", "page_number": 2, "text": "neural network text"}])


def test_query_returns_response(tmp_path):
    rag, vs, _, _ = make_rag(tmp_path)
    seed_store(vs)
    result = asyncio.run(rag.query("What is deep learning?", ["p1"], {"p1": "TestPaper"}))
    assert result.text
    assert isinstance(result.citations, list)


def test_query_no_results(tmp_path):
    rag, _, _, _ = make_rag(tmp_path)  # empty store
    result = asyncio.run(rag.query("What?", ["p1"], {"p1": "Test"}))
    assert "couldn't find" in result.text.lower()
    assert result.citations == []


def test_context_construction(tmp_path):
    rag, _, _, _ = make_rag(tmp_path)
    results = [SearchResult("c1", "p1", 3, "some text", 0.9)]
    ctx = rag._build_context(results, {"p1": "My Paper"})
    assert "My Paper" in ctx
    assert "Page 3" in ctx
    assert "some text" in ctx


def test_slash_command_search(tmp_path):
    rag, vs, _, _ = make_rag(tmp_path)
    seed_store(vs)
    result = asyncio.run(rag.execute_command("/search", "deep learning", ["p1"], {"p1": "Test"}))
    assert result.text


def test_slash_command_unknown(tmp_path):
    rag, _, _, _ = make_rag(tmp_path)
    result = asyncio.run(rag.execute_command("/unknown", None, ["p1"], {}))
    assert "unknown command" in result.text.lower()
