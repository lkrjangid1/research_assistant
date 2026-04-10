import logging
from enum import Enum
from app.services.vertex_ai_client import VertexAIClient

logger = logging.getLogger(__name__)

MAX_CONTENT_CHARS = 8000


class ExpertiseLevel(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    EXPERT = "expert"


_PROMPTS = {
    ExpertiseLevel.BEGINNER: (
        "You are explaining a research paper to someone new to the field.\n"
        "Use simple language, avoid jargon (or explain it when necessary), and use analogies.\n"
        "Focus on: What problem does this solve? Why does it matter? What's the main idea?\n\n"
        "Paper Content:\n{content}\n\n"
        "Generate a beginner-friendly summary in 3-4 paragraphs."
    ),
    ExpertiseLevel.INTERMEDIATE: (
        "You are explaining a research paper to a graduate student or practitioner.\n"
        "Balance technical accuracy with accessibility. Include methodology overview.\n"
        "Focus on: Problem statement, proposed solution, key contributions, experimental results.\n\n"
        "Paper Content:\n{content}\n\n"
        "Generate an intermediate-level summary covering methodology and results."
    ),
    ExpertiseLevel.EXPERT: (
        "You are writing a technical summary for a domain expert.\n"
        "Be concise and technical. Focus on novel contributions and methodological details.\n"
        "Highlight: Technical innovations, experimental setup, quantitative results, limitations.\n\n"
        "Paper Content:\n{content}\n\n"
        "Generate an expert-level technical summary."
    ),
}

_KEY_POINTS_SUFFIX = (
    "\n\nAfter the summary, provide exactly 5 key points as a numbered list "
    "prefixed with 'KEY_POINTS:' on its own line."
)


class SummarizerService:
    """Generate adaptive summaries based on user expertise level."""

    def __init__(self, llm_client: VertexAIClient):
        self.llm_client = llm_client

    async def summarize(self, content: str, level: ExpertiseLevel = ExpertiseLevel.INTERMEDIATE) -> str:
        prompt = _PROMPTS[level].format(content=content[:MAX_CONTENT_CHARS])
        return await self.llm_client.generate(prompt)

    async def summarize_with_key_points(
        self, content: str, level: ExpertiseLevel = ExpertiseLevel.INTERMEDIATE
    ) -> tuple[str, list[str]]:
        prompt = _PROMPTS[level].format(content=content[:MAX_CONTENT_CHARS]) + _KEY_POINTS_SUFFIX
        response = await self.llm_client.generate(prompt)

        if "KEY_POINTS:" in response:
            summary_part, kp_part = response.split("KEY_POINTS:", 1)
            summary = summary_part.strip()
            key_points = [
                line.strip().lstrip("0123456789.-) ").strip()
                for line in kp_part.strip().splitlines()
                if line.strip()
            ][:5]
        else:
            summary = response.strip()
            key_points = []

        return summary, key_points
