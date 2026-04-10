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
