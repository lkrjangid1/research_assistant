import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.responses import RedirectResponse

from app.config import get_settings
from app.core.middleware import setup_cors, setup_rate_limiter, setup_timing_middleware
from app.core.exceptions import register_exception_handlers
from app.api.routes import health, papers, chat, summary
from app.api.dependencies import get_vector_store

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: load FAISS index from disk
    vs = get_vector_store()
    vs.load()
    logger.info("Startup complete. FAISS vectors: %d", vs.total_vectors)
    yield
    # Shutdown: persist FAISS index
    vs.save()
    logger.info("Shutdown complete.")


app = FastAPI(
    title="Research Paper RAG API",
    description="AI-powered research paper search, summarization, and chat backend.",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    swagger_ui_parameters={
        "displayRequestDuration": True,
        "tryItOutEnabled": True,
    },
)


@app.get("/", include_in_schema=False)
async def root():
    return RedirectResponse(url="/docs")

setup_cors(app)
setup_rate_limiter(app)
setup_timing_middleware(app)
register_exception_handlers(app)

app.include_router(health.router)
app.include_router(papers.router)
app.include_router(chat.router)
app.include_router(summary.router)
