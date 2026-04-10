import logging
from fastapi import APIRouter
from app.models.requests import SummaryRequest, SummaryResponse
from app.services.summarizer import ExpertiseLevel
from app.api.dependencies import get_summarizer_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/summary", tags=["Summary"])


@router.post("/generate", response_model=SummaryResponse)
async def generate_summary(request: SummaryRequest):
    summarizer = get_summarizer_service()
    level = ExpertiseLevel(request.level)
    summary, key_points = await summarizer.summarize_with_key_points(request.content, level)
    return SummaryResponse(summary=summary, key_points=key_points, level=request.level)
