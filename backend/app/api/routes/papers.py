import logging
import uuid
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException
from app.models.requests import ProcessPaperRequest, ProcessPaperResponse, PaperStatusResponse
from app.models.paper import PaperStatus, ProcessingStatus
from app.api.dependencies import (
    get_pdf_processor, get_chunker, get_embedding_service, get_vector_store,
    get_paper_status_store, set_paper_status,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/papers", tags=["Papers"])


async def _process_paper_task(
    request: ProcessPaperRequest,
    pdf_processor, chunker, embedding_service, vector_store,
) -> None:
    paper_id = request.paper_id
    try:
        import httpx
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.get(request.pdf_url)
            response.raise_for_status()
            pdf_bytes = response.content

        doc = await pdf_processor.process_pdf(pdf_bytes, paper_id)
        chunks = chunker.chunk_document(doc.pages, paper_id)

        if not chunks:
            set_paper_status(paper_id, PaperStatus(
                paper_id=paper_id, status=ProcessingStatus.FAILED,
                error_message="No text could be extracted from PDF",
            ))
            return

        texts = [c.text for c in chunks]
        embeddings = await embedding_service.embed_texts(texts)
        chunk_ids = [c.chunk_id for c in chunks]
        metadata = [{"paper_id": c.paper_id, "page_number": c.page_number, "text": c.text} for c in chunks]

        vector_store.add_embeddings(embeddings, chunk_ids, metadata)
        vector_store.save()

        set_paper_status(paper_id, PaperStatus(
            paper_id=paper_id, status=ProcessingStatus.COMPLETED, total_chunks=len(chunks),
        ))
        logger.info("Paper %s processed successfully: %d chunks", paper_id, len(chunks))

    except Exception as exc:
        logger.error("Paper processing failed for %s: %s", paper_id, exc)
        set_paper_status(paper_id, PaperStatus(
            paper_id=paper_id, status=ProcessingStatus.FAILED, error_message=str(exc),
        ))


@router.post("/process", response_model=ProcessPaperResponse)
async def process_paper(
    request: ProcessPaperRequest,
    background_tasks: BackgroundTasks,
):
    paper_id = request.paper_id
    set_paper_status(paper_id, PaperStatus(paper_id=paper_id, status=ProcessingStatus.PROCESSING))

    background_tasks.add_task(
        _process_paper_task,
        request,
        get_pdf_processor(),
        get_chunker(),
        get_embedding_service(),
        get_vector_store(),
    )
    return ProcessPaperResponse(paper_id=paper_id, status="processing", message="PDF processing started")


@router.get("/{paper_id}/status", response_model=PaperStatusResponse)
async def paper_status(paper_id: str):
    store = get_paper_status_store()
    status = store.get(paper_id)
    if not status:
        raise HTTPException(status_code=404, detail=f"Paper '{paper_id}' not found")
    return PaperStatusResponse(
        paper_id=status.paper_id,
        status=status.status.value,
        total_chunks=status.total_chunks,
        error_message=status.error_message,
    )


@router.delete("/{paper_id}")
async def delete_paper(paper_id: str):
    vector_store = get_vector_store()
    store = get_paper_status_store()
    if paper_id not in store:
        raise HTTPException(status_code=404, detail=f"Paper '{paper_id}' not found")
    vector_store.remove_paper(paper_id)
    vector_store.save()
    store.pop(paper_id, None)
    return {"message": f"Paper '{paper_id}' removed from index"}
