import uuid
import logging
from fastapi import APIRouter, HTTPException
from app.models.requests import (
    ChatQueryRequest, ChatQueryResponse, CitationResponse,
    SlashCommandRequest, SlashCommandResponse,
)
from app.api.dependencies import get_rag_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/chat", tags=["Chat"])


@router.post("/query", response_model=ChatQueryResponse)
async def chat_query(request: ChatQueryRequest):
    rag = get_rag_service()
    result = await rag.query(
        question=request.question,
        paper_ids=request.paper_ids,
        paper_titles=request.paper_titles,
    )
    session_id = request.session_id or str(uuid.uuid4())
    return ChatQueryResponse(
        text=result.text,
        citations=[
            CitationResponse(
                paper_title=c.paper_title,
                page_number=c.page_number,
                excerpt=c.excerpt,
            )
            for c in result.citations
        ],
        session_id=session_id,
    )


@router.post("/command", response_model=SlashCommandResponse)
async def chat_command(request: SlashCommandRequest):
    rag = get_rag_service()
    result = await rag.execute_command(
        command=request.command,
        args=request.args,
        paper_ids=request.paper_ids,
        paper_titles=request.paper_titles,
    )
    session_id = request.session_id or str(uuid.uuid4())
    return SlashCommandResponse(
        text=result.text,
        citations=[
            CitationResponse(
                paper_title=c.paper_title,
                page_number=c.page_number,
                excerpt=c.excerpt,
            )
            for c in result.citations
        ],
        command=request.command,
        session_id=session_id,
    )
