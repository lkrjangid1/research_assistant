from pydantic import BaseModel, Field
from typing import Optional


# ── Papers ─────────────────────────────────────────────────────────────────────

class ProcessPaperRequest(BaseModel):
    paper_id: str
    title: str
    authors: list[str]
    pdf_url: str = Field(..., description="arXiv PDF URL; backend downloads it")


class ProcessPaperResponse(BaseModel):
    paper_id: str
    status: str
    message: str


class PaperStatusResponse(BaseModel):
    paper_id: str
    status: str
    total_chunks: int = 0
    error_message: Optional[str] = None


# ── Chat ───────────────────────────────────────────────────────────────────────

class CitationResponse(BaseModel):
    paper_title: str
    page_number: int
    excerpt: str


class ChatQueryRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=2000)
    paper_ids: list[str] = Field(..., min_length=1, max_length=3)
    paper_titles: dict[str, str] = Field(default_factory=dict)
    session_id: Optional[str] = None
    expertise_level: Optional[str] = "intermediate"


class ChatQueryResponse(BaseModel):
    text: str
    citations: list[CitationResponse]
    session_id: str
    tokens_used: int = 0


class SlashCommandRequest(BaseModel):
    command: str
    paper_ids: list[str] = Field(..., min_length=1, max_length=3)
    paper_titles: dict[str, str] = Field(default_factory=dict)
    args: Optional[str] = None
    session_id: Optional[str] = None


class SlashCommandResponse(BaseModel):
    text: str
    citations: list[CitationResponse]
    command: str
    session_id: str


# ── Summary ────────────────────────────────────────────────────────────────────

class SummaryRequest(BaseModel):
    paper_id: str
    level: str = Field(default="intermediate", pattern="^(beginner|intermediate|expert)$")
    content: str = Field(..., description="Paper text (abstract or full text)")
    focus: Optional[str] = Field(default="full", pattern="^(methodology|results|contributions|full)$")


class SummaryResponse(BaseModel):
    summary: str
    key_points: list[str]
    level: str


# ── Health ─────────────────────────────────────────────────────────────────────

class HealthResponse(BaseModel):
    status: str
    version: str = "1.0.0"


class ReadyResponse(BaseModel):
    status: str
    faiss_loaded: bool
    vertex_ai_connected: bool
