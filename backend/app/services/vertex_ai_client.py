import logging

import httpx
from google.auth.credentials import Credentials

from app.core.exceptions import RAGError
from app.services.vertex_auth import VertexAuth, VertexAuthError

logger = logging.getLogger(__name__)

_VERTEX_MODEL_PATH = (
    "projects/{project}/locations/{location}/publishers/google/models/{model}"
)
_VERTEX_GENERATE_URL = "https://aiplatform.googleapis.com/v1/{model}:generateContent"


class VertexAIClient:
    """Vertex AI Gemini REST client using Application Default Credentials."""

    def __init__(
        self,
        project_id: str = "",
        location: str = "us-central1",
        model_name: str = "gemini-2.5-flash-lite",
        credentials: Credentials | None = None,
        credentials_path: str = "",
    ):
        self.location = location.strip() or "us-central1"
        self.model_name = model_name.strip()
        self._auth = VertexAuth(project_id, credentials, credentials_path)

    async def generate(
        self,
        prompt: str,
        temperature: float = 0.3,
        max_output_tokens: int = 2048,
        top_p: float = 0.95,
    ) -> str:
        payload = {
            "contents": [
                {
                    "role": "user",
                    "parts": [{"text": prompt}],
                }
            ],
            "generationConfig": {
                "temperature": temperature,
                "topP": top_p,
                "maxOutputTokens": max_output_tokens,
            },
        }

        try:
            url = await self._generate_url()
            headers = await self._auth.headers()
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    url,
                    headers=headers,
                    json=payload,
                )
                response.raise_for_status()
        except VertexAuthError as exc:
            logger.error("Vertex AI auth failed: %s", exc)
            raise RAGError(f"Generation failed: {exc}") from exc
        except httpx.HTTPStatusError as exc:
            detail = exc.response.text
            logger.error("Vertex AI generation failed: %s", detail)
            raise RAGError(f"Generation failed: {detail}") from exc
        except httpx.HTTPError as exc:
            logger.error("Vertex AI request failed: %s", exc)
            raise RAGError(f"Generation failed: {exc}") from exc

        data = response.json()
        try:
            parts = data["candidates"][0]["content"]["parts"]
            text = "".join(part.get("text", "") for part in parts).strip()
        except (KeyError, IndexError, TypeError) as exc:
            logger.error("Unexpected Vertex AI response: %s", data)
            raise RAGError("Generation failed: unexpected Vertex AI response.") from exc

        if not text:
            raise RAGError("Generation failed: empty response from Vertex AI.")
        return text

    async def _generate_url(self) -> str:
        return _VERTEX_GENERATE_URL.format(model=await self._model_path())

    async def _model_path(self) -> str:
        if self.model_name.startswith("projects/"):
            return self.model_name
        project = await self._auth.project()
        if self.model_name.startswith("publishers/"):
            return f"projects/{project}/locations/{self.location}/{self.model_name}"
        return _VERTEX_MODEL_PATH.format(
            project=project,
            location=self.location,
            model=self.model_name,
        )
