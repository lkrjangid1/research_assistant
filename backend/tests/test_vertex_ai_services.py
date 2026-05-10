import httpx
import numpy as np
import pytest

from app.services.embedding_service import EmbeddingService
from app.services.vertex_ai_client import VertexAIClient
from app.services.vertex_auth import VertexAuth


class FakeCredentials:
    token = "test-token"
    valid = True
    project_id = "test-project"

    def refresh(self, request):
        raise AssertionError("valid fake credentials should not be refreshed")


class MockAsyncClient:
    calls: list[dict] = []
    response_json: dict = {}
    responses: list["MockResponse"] = []

    def __init__(self, timeout):
        self.timeout = timeout

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, tb):
        return None

    async def post(self, url, **kwargs):
        self.calls.append({"url": url, **kwargs})
        if self.responses:
            return self.responses.pop(0)
        return MockResponse(self.response_json)


class MockResponse:
    def __init__(self, data, status_code=200, headers=None):
        self._data = data
        self.status_code = status_code
        self.headers = headers or {}

    def raise_for_status(self):
        if self.status_code < 400:
            return None

        response = httpx.Response(
            self.status_code,
            json=self._data,
            headers=self.headers,
            request=httpx.Request("POST", "https://example.test"),
        )
        raise httpx.HTTPStatusError("mock error", request=response.request, response=response)

    def json(self):
        return self._data


@pytest.mark.asyncio
async def test_vertex_generate_uses_prod_aiplatform_endpoint(monkeypatch):
    MockAsyncClient.calls = []
    MockAsyncClient.responses = []
    MockAsyncClient.response_json = {
        "candidates": [{"content": {"parts": [{"text": "ok"}]}}],
    }
    monkeypatch.setattr("app.services.vertex_ai_client.httpx.AsyncClient", MockAsyncClient)

    client = VertexAIClient(
        project_id="test-project",
        location="us-central1",
        model_name="gemini-2.5-flash-lite",
        credentials=FakeCredentials(),
    )

    assert await client.generate("hello") == "ok"

    call = MockAsyncClient.calls[0]
    assert call["url"] == (
        "https://aiplatform.googleapis.com/v1/projects/test-project/locations/"
        "us-central1/publishers/google/models/gemini-2.5-flash-lite:generateContent"
    )
    assert call["headers"] == {"Authorization": "Bearer test-token"}
    assert "params" not in call
    assert call["json"]["contents"][0]["parts"][0]["text"] == "hello"


@pytest.mark.asyncio
async def test_embedding_uses_vertex_predict_endpoint(monkeypatch):
    MockAsyncClient.calls = []
    MockAsyncClient.responses = []
    MockAsyncClient.response_json = {
        "predictions": [{"embeddings": {"values": [0.1, 0.2, 0.3]}}],
    }
    monkeypatch.setattr("app.services.embedding_service.httpx.AsyncClient", MockAsyncClient)

    service = EmbeddingService(
        project_id="test-project",
        location="us-central1",
        model_name="gemini-embedding-001",
        embedding_dim=3,
        credentials=FakeCredentials(),
    )

    embeddings = await service.embed_texts(["hello"], task_type="RETRIEVAL_DOCUMENT")

    call = MockAsyncClient.calls[0]
    assert call["url"] == (
        "https://us-central1-aiplatform.googleapis.com/v1/projects/test-project/locations/"
        "us-central1/publishers/google/models/gemini-embedding-001:predict"
    )
    assert call["headers"] == {"Authorization": "Bearer test-token"}
    assert "params" not in call
    assert call["json"]["instances"] == [
        {"content": "hello", "task_type": "RETRIEVAL_DOCUMENT"}
    ]
    assert call["json"]["parameters"]["outputDimensionality"] == 3
    assert np.array_equal(embeddings, np.array([[0.1, 0.2, 0.3]], dtype=np.float32))


@pytest.mark.asyncio
async def test_embedding_retries_quota_throttles(monkeypatch):
    sleeps = []

    async def fake_sleep(delay):
        sleeps.append(delay)

    MockAsyncClient.calls = []
    MockAsyncClient.responses = [
        MockResponse({"error": {"message": "quota"}}, status_code=429, headers={"retry-after": "0"}),
        MockResponse({"predictions": [{"embeddings": {"values": [0.4, 0.5, 0.6]}}]}),
    ]
    monkeypatch.setattr("app.services.embedding_service.httpx.AsyncClient", MockAsyncClient)
    monkeypatch.setattr("app.services.embedding_service.asyncio.sleep", fake_sleep)

    service = EmbeddingService(
        project_id="test-project",
        location="us-central1",
        model_name="gemini-embedding-001",
        embedding_dim=3,
        credentials=FakeCredentials(),
        requests_per_minute=0,
        max_retries=1,
    )

    embeddings = await service.embed_texts(["hello"], task_type="RETRIEVAL_DOCUMENT")

    assert len(MockAsyncClient.calls) == 2
    assert sleeps == [0.0]
    assert np.array_equal(embeddings, np.array([[0.4, 0.5, 0.6]], dtype=np.float32))


@pytest.mark.asyncio
async def test_vertex_auth_loads_service_account_path_from_settings(monkeypatch):
    calls = []

    def fake_from_service_account_file(path, scopes):
        calls.append((path, scopes))
        return FakeCredentials()

    monkeypatch.setattr(
        "app.services.vertex_auth.service_account.Credentials.from_service_account_file",
        fake_from_service_account_file,
    )

    auth = VertexAuth(credentials_path="~/service-account.json")

    assert await auth.headers() == {"Authorization": "Bearer test-token"}
    assert await auth.project() == "test-project"
    assert calls[0][0].endswith("/service-account.json")
    assert calls[0][1] == ["https://www.googleapis.com/auth/cloud-platform"]
