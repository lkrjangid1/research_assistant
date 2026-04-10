import logging

import httpx

from app.core.exceptions import RAGError

logger = logging.getLogger(__name__)

_GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"


class VertexAIClient:
    """Gemini API client using API-key based REST calls."""

    def __init__(self, api_key: str, model_name: str = "gemini-2.5-flash-lite"):
        self.api_key = api_key
        self.model_name = model_name

    async def generate(
        self,
        prompt: str,
        temperature: float = 0.3,
        max_output_tokens: int = 2048,
        top_p: float = 0.95,
    ) -> str:
        if not self.api_key:
            raise RAGError("Generation failed: GEMINI_API_KEY is not configured.")

        url = _GEMINI_API_URL.format(model=self.model_name)
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
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    url,
                    params={"key": self.api_key},
                    json=payload,
                )
                response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            detail = exc.response.text
            logger.error("Gemini API generation failed: %s", detail)
            raise RAGError(f"Generation failed: {detail}") from exc
        except httpx.HTTPError as exc:
            logger.error("Gemini API request failed: %s", exc)
            raise RAGError(f"Generation failed: {exc}") from exc

        data = response.json()
        try:
            parts = data["candidates"][0]["content"]["parts"]
            text = "".join(part.get("text", "") for part in parts).strip()
        except (KeyError, IndexError, TypeError) as exc:
            logger.error("Unexpected Gemini API response: %s", data)
            raise RAGError("Generation failed: unexpected Gemini API response.") from exc

        if not text:
            raise RAGError("Generation failed: empty response from Gemini API.")
        return text
