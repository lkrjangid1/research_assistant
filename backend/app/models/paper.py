from enum import Enum
from datetime import datetime
from pydantic import BaseModel


class ProcessingStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class PaperMetadata(BaseModel):
    paper_id: str
    title: str
    authors: list[str]
    abstract: str = ""
    pdf_url: str
    published_date: datetime | None = None
    categories: list[str] = []


class PaperStatus(BaseModel):
    paper_id: str
    status: ProcessingStatus
    total_chunks: int = 0
    processed_chunks: int = 0
    current_step: str = ""
    estimated_seconds_remaining: int | None = None
    pdf_size_bytes: int | None = None
    error_message: str | None = None
