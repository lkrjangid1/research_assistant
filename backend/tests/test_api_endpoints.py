import pytest
from fastapi.testclient import TestClient


def test_health(test_client):
    r = test_client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "healthy"


def test_health_ready(test_client):
    r = test_client.get("/health/ready")
    assert r.status_code == 200
    data = r.json()
    assert data["faiss_loaded"] is True


def test_paper_not_found(test_client):
    r = test_client.get("/api/papers/nonexistent_paper/status")
    assert r.status_code == 404


def test_chat_query_success(test_client):
    r = test_client.post("/api/chat/query", json={
        "question": "What is the main contribution?",
        "paper_ids": ["2401.12345"],
        "paper_titles": {"2401.12345": "Test Paper"},
    })
    assert r.status_code == 200
    data = r.json()
    assert "text" in data
    assert "citations" in data
    assert "session_id" in data


def test_chat_query_validation_missing_question(test_client):
    r = test_client.post("/api/chat/query", json={"paper_ids": ["abc"]})
    assert r.status_code == 422


def test_chat_query_validation_too_many_papers(test_client):
    r = test_client.post("/api/chat/query", json={
        "question": "test",
        "paper_ids": ["a", "b", "c", "d"],  # max 3
    })
    assert r.status_code == 422


def test_chat_command(test_client):
    r = test_client.post("/api/chat/command", json={
        "command": "/summary",
        "paper_ids": ["abc"],
        "args": "beginner",
    })
    assert r.status_code == 200
    data = r.json()
    assert "command" in data


def test_upload_paper_pdf_success(
    test_client,
    sample_pdf_bytes,
    pdf_processor,
    chunker,
    vector_store,
    mock_embedding_service,
    monkeypatch,
    tmp_path,
):
    from app.api.routes import papers

    monkeypatch.setattr(papers, "_PDF_CACHE_DIR", tmp_path / "pdf_cache")
    monkeypatch.setattr(papers, "get_pdf_processor", lambda: pdf_processor)
    monkeypatch.setattr(papers, "get_chunker", lambda: chunker)
    monkeypatch.setattr(papers, "get_embedding_service", lambda: mock_embedding_service)
    monkeypatch.setattr(papers, "get_vector_store", lambda: vector_store)

    response = test_client.post(
        "/api/papers/upload",
        files={"file": ("test-paper.pdf", sample_pdf_bytes, "application/pdf")},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["paper_id"].startswith("upload-")
    assert data["title"] == "test-paper"
    assert data["status"] == "processing"

    paper_id = data["paper_id"]

    status = test_client.get(f"/api/papers/{paper_id}/status")
    assert status.status_code == 200
    assert status.json()["status"] == "completed"

    pdf = test_client.get(f"/api/papers/{paper_id}/pdf")
    assert pdf.status_code == 200
    assert pdf.headers["content-type"] == "application/pdf"


def test_upload_paper_rejects_non_pdf(test_client):
    response = test_client.post(
        "/api/papers/upload",
        files={"file": ("notes.txt", b"not a pdf", "text/plain")},
    )
    assert response.status_code == 400
