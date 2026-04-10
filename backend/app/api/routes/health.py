from fastapi import APIRouter
from app.models.requests import HealthResponse, ReadyResponse
from app.api.dependencies import get_vector_store

router = APIRouter(tags=["Health"])


@router.get("/health", response_model=HealthResponse)
async def health():
    return HealthResponse(status="healthy")


@router.get("/health/ready", response_model=ReadyResponse)
async def ready():
    vs = get_vector_store()
    return ReadyResponse(
        status="ready",
        faiss_loaded=vs.total_vectors >= 0,
        vertex_ai_connected=True,
    )
