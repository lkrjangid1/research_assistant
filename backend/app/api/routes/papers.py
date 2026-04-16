import logging
import time
from pathlib import Path

import httpx
from fastapi import APIRouter, BackgroundTasks, HTTPException
from app.models.requests import ProcessPaperRequest, ProcessPaperResponse, PaperStatusResponse
from app.models.paper import PaperStatus, ProcessingStatus
from app.api.dependencies import (
    get_pdf_processor, get_chunker, get_embedding_service, get_vector_store,
    get_paper_status_store, set_paper_status,
)
from app.config import get_settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/papers", tags=["Papers"])

_PDF_CACHE_DIR = Path(get_settings().faiss_index_path).parent / "pdf_cache"


async def _download_pdf(url: str, paper_id: str) -> bytes:
    """Download a PDF with on-disk caching so repeat indexes are instant."""
    cache_file = _PDF_CACHE_DIR / f"{paper_id}.pdf"
    if cache_file.exists():
        pdf_bytes = cache_file.read_bytes()
        logger.info("[%s] PDF cache hit (%d KB)", paper_id, len(pdf_bytes) // 1024)
        return pdf_bytes

    async with httpx.AsyncClient(timeout=120.0, follow_redirects=True) as client:
        response = await client.get(url)
        response.raise_for_status()
        pdf_bytes = response.content

    _PDF_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file.write_bytes(pdf_bytes)
    return pdf_bytes


async def _process_paper_task(
    request: ProcessPaperRequest,
    pdf_processor, chunker, embedding_service, vector_store,
) -> None:
    paper_id = request.paper_id
    try:
        t0 = time.time()

        # Race-condition guard: another task may have finished first
        if vector_store.has_paper(paper_id):
            set_paper_status(paper_id, PaperStatus(
                paper_id=paper_id, status=ProcessingStatus.COMPLETED,
            ))
            logger.info("[%s] Already indexed — skipped", paper_id)
            return

        pdf_bytes = await _download_pdf(request.pdf_url, paper_id)
        t1 = time.time()
        logger.info("[%s] PDF ready in %.1fs (%d KB)", paper_id, t1 - t0, len(pdf_bytes) // 1024)

        doc = await pdf_processor.process_pdf(pdf_bytes, paper_id)
        t2 = time.time()
        logger.info("[%s] Text extracted in %.1fs (%d pages)", paper_id, t2 - t1, len(doc.pages))

        chunks = chunker.chunk_document(doc.pages, paper_id)
        if not chunks:
            set_paper_status(paper_id, PaperStatus(
                paper_id=paper_id, status=ProcessingStatus.FAILED,
                error_message="No text could be extracted from PDF",
            ))
            return
        t3 = time.time()
        logger.info("[%s] Chunked in %.1fs (%d chunks)", paper_id, t3 - t2, len(chunks))

        texts = [c.text for c in chunks]
        embeddings = await embedding_service.embed_texts(texts)
        t4 = time.time()
        logger.info("[%s] Embedded in %.1fs", paper_id, t4 - t3)

        chunk_ids = [c.chunk_id for c in chunks]
        metadata = [{"paper_id": c.paper_id, "page_number": c.page_number, "text": c.text} for c in chunks]
        vector_store.add_embeddings(embeddings, chunk_ids, metadata)
        vector_store.save()
        t5 = time.time()
        logger.info("[%s] FAISS indexed + saved in %.1fs", paper_id, t5 - t4)

        set_paper_status(paper_id, PaperStatus(
            paper_id=paper_id, status=ProcessingStatus.COMPLETED, total_chunks=len(chunks),
        ))
        logger.info("[%s] TOTAL: %.1fs (%d chunks)", paper_id, t5 - t0, len(chunks))

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

    # ── Fast exit: already indexed (survives server restarts via FAISS persistence) ──
    vs = get_vector_store()
    if vs.has_paper(paper_id):
        set_paper_status(paper_id, PaperStatus(
            paper_id=paper_id, status=ProcessingStatus.COMPLETED,
        ))
        return ProcessPaperResponse(
            paper_id=paper_id, status="completed",
            message="Paper already indexed",
        )

    # ── Dedup: already being processed ───────────────────────────────────────
    store = get_paper_status_store()
    existing = store.get(paper_id)
    if existing and existing.status == ProcessingStatus.PROCESSING:
        return ProcessPaperResponse(
            paper_id=paper_id, status="processing",
            message="Paper is already being processed",
        )

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

    # Status store is in-memory and lost on restart. Fall back to the
    # persisted FAISS index so clients don't re-index papers needlessly.
    if not status:
        vs = get_vector_store()
        if vs.has_paper(paper_id):
            status = PaperStatus(paper_id=paper_id, status=ProcessingStatus.COMPLETED)
            store[paper_id] = status
        else:
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
    if paper_id not in store and not vector_store.has_paper(paper_id):
        raise HTTPException(status_code=404, detail=f"Paper '{paper_id}' not found")
    vector_store.remove_paper(paper_id)
    vector_store.save()
    store.pop(paper_id, None)
    return {"message": f"Paper '{paper_id}' removed from index"}
