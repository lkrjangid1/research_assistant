import asyncio
import logging
from app.core.exceptions import RAGError

logger = logging.getLogger(__name__)


class VertexAIClient:
    """Wrapper around Vertex AI Gemini 1.5 Pro for text generation."""

    def __init__(self, project_id: str, location: str, model_name: str = "gemini-1.5-pro"):
        self.project_id = project_id
        self.location = location
        self.model_name = model_name
        self._model = None

    def _get_model(self):
        if self._model is None:
            import vertexai
            from vertexai.generative_models import GenerativeModel
            vertexai.init(project=self.project_id, location=self.location)
            self._model = GenerativeModel(self.model_name)
        return self._model

    async def generate(
        self,
        prompt: str,
        temperature: float = 0.3,
        max_output_tokens: int = 2048,
        top_p: float = 0.95,
    ) -> str:
        """Generate text from a prompt using Gemini."""
        try:
            return await asyncio.to_thread(
                self._generate_sync, prompt, temperature, max_output_tokens, top_p
            )
        except Exception as exc:
            logger.error("Vertex AI generation failed: %s", exc)
            raise RAGError(f"Generation failed: {exc}") from exc

    def _generate_sync(
        self, prompt: str, temperature: float, max_output_tokens: int, top_p: float
    ) -> str:
        from vertexai.generative_models import GenerationConfig
        model = self._get_model()
        config = GenerationConfig(
            temperature=temperature,
            max_output_tokens=max_output_tokens,
            top_p=top_p,
        )
        response = model.generate_content(prompt, generation_config=config)
        return response.text
