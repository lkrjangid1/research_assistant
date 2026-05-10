import logging
import re
import time
from hashlib import sha1
from pathlib import Path

import httpx
from fastapi import (
    APIRouter,
    BackgroundTasks,
    File,
    Form,
    HTTPException,
    Query,
    UploadFile,
)
from fastapi.responses import FileResponse
from app.models.requests import (
    PaperStatusResponse,
    PdfSizeResponse,
    ProcessPaperRequest,
    ProcessPaperResponse,
    UploadPaperResponse,
)
from app.models.paper import PaperStatus, ProcessingStatus
from app.api.dependencies import (
    get_pdf_processor, get_chunker, get_embedding_service, get_vector_store,
    get_paper_status_store, set_paper_status,
)
from app.config import get_settings

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/api/papers", tags=["Papers"])

_PDF_CACHE_DIR = Path(get_settings().faiss_index_path).parent / "pdf_cache"
_CONTENT_RANGE_TOTAL_RE = re.compile(r"/(\d+)$")


def _pdf_cache_path(paper_id: str) -> Path:
    return _PDF_CACHE_DIR / f"{paper_id}.pdf"


async def _download_pdf(url: str, paper_id: str) -> bytes:
    """Download a PDF with on-disk caching so repeat indexes are instant."""
    cache_file = _pdf_cache_path(paper_id)
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


def _cache_pdf_bytes(paper_id: str, pdf_bytes: bytes) -> None:
    _PDF_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    _pdf_cache_path(paper_id).write_bytes(pdf_bytes)


def _cached_pdf_size(paper_id: str | None) -> int | None:
    if not paper_id:
        return None
    pdf_path = _pdf_cache_path(paper_id)
    if not pdf_path.exists():
        return None
    return pdf_path.stat().st_size


async def _remote_pdf_size(url: str) -> int | None:
    async with httpx.AsyncClient(timeout=20.0, follow_redirects=True) as client:
        try:
            response = await client.head(url)
            response.raise_for_status()
            content_length = response.headers.get("content-length")
            if content_length and content_length.isdigit():
                return int(content_length)
        except httpx.HTTPError:
            logger.info("PDF HEAD size lookup failed for %s; trying range GET", url)

        request = client.build_request("GET", url, headers={"Range": "bytes=0-0"})
        response = await client.send(request, stream=True)
        try:
            response.raise_for_status()
            content_range = response.headers.get("content-range", "")
            match = _CONTENT_RANGE_TOTAL_RE.search(content_range)
            if match:
                return int(match.group(1))

        finally:
            await response.aclose()
    return None


def _uploaded_title(filename: str | None, title: str | None) -> str:
    if title and title.strip():
        return title.strip()
    if filename:
        return Path(filename).stem.replace("_", " ").strip() or "Uploaded PDF"
    return "Uploaded PDF"


def _set_processing_status(
    paper_id: str,
    current_step: str,
    total_chunks: int = 0,
    processed_chunks: int = 0,
    estimated_seconds_remaining: int | None = None,
    pdf_size_bytes: int | None = None,
) -> None:
    previous = get_paper_status_store().get(paper_id)
    known_pdf_size = (
        pdf_size_bytes
        if pdf_size_bytes is not None
        else previous.pdf_size_bytes
        if previous
        else None
    )
    set_paper_status(paper_id, PaperStatus(
        paper_id=paper_id,
        status=ProcessingStatus.PROCESSING,
        total_chunks=total_chunks,
        processed_chunks=processed_chunks,
        current_step=current_step,
        estimated_seconds_remaining=estimated_seconds_remaining,
        pdf_size_bytes=known_pdf_size,
    ))


async def _index_pdf_bytes(
    paper_id: str,
    pdf_bytes: bytes,
    pdf_processor,
    chunker,
    embedding_service,
    vector_store,
) -> None:
    t0 = time.time()
    pdf_size_bytes = len(pdf_bytes)
    _set_processing_status(paper_id, "extracting_text", pdf_size_bytes=pdf_size_bytes)
    doc = await pdf_processor.process_pdf(pdf_bytes, paper_id)
    t1 = time.time()
    logger.info("[%s] Text extracted in %.1fs (%d pages)", paper_id, t1 - t0, len(doc.pages))

    _set_processing_status(paper_id, "chunking", pdf_size_bytes=pdf_size_bytes)
    chunks = chunker.chunk_document(doc.pages, paper_id)
    if not chunks:
        set_paper_status(paper_id, PaperStatus(
            paper_id=paper_id, status=ProcessingStatus.FAILED,
            current_step="failed",
            pdf_size_bytes=pdf_size_bytes,
            error_message="No text could be extracted from PDF",
        ))
        return
    t2 = time.time()
    logger.info("[%s] Chunked in %.1fs (%d chunks)", paper_id, t2 - t1, len(chunks))

    texts = [c.text for c in chunks]
    seconds_per_embedding = getattr(
        embedding_service,
        "estimated_seconds_per_uncached_embedding",
        0,
    )
    estimated_total = int(len(chunks) * seconds_per_embedding)
    _set_processing_status(
        paper_id,
        "embedding",
        total_chunks=len(chunks),
        estimated_seconds_remaining=estimated_total,
        pdf_size_bytes=pdf_size_bytes,
    )
    logger.info(
        "[%s] Embedding %d chunks; current rate limit estimates up to %ds",
        paper_id, len(chunks), estimated_total,
    )

    async def _embedding_progress(done: int, total: int) -> None:
        remaining = max(0, int((total - done) * seconds_per_embedding))
        _set_processing_status(
            paper_id,
            "embedding",
            total_chunks=len(chunks),
            processed_chunks=done,
            estimated_seconds_remaining=remaining,
            pdf_size_bytes=pdf_size_bytes,
        )
        logger.info(
            "[%s] Embedded %d/%d chunks (ETA ~%ds)",
            paper_id, done, len(chunks), remaining,
        )

    embeddings = await embedding_service.embed_texts(
        texts,
        progress_callback=_embedding_progress,
    )
    t3 = time.time()
    logger.info("[%s] Embedded in %.1fs", paper_id, t3 - t2)

    _set_processing_status(
        paper_id,
        "indexing",
        total_chunks=len(chunks),
        processed_chunks=len(chunks),
        estimated_seconds_remaining=0,
        pdf_size_bytes=pdf_size_bytes,
    )
    chunk_ids = [c.chunk_id for c in chunks]
    metadata = [{"paper_id": c.paper_id, "page_number": c.page_number, "text": c.text} for c in chunks]
    vector_store.add_embeddings(embeddings, chunk_ids, metadata)
    vector_store.save()
    t4 = time.time()
    logger.info("[%s] FAISS indexed + saved in %.1fs", paper_id, t4 - t3)

    set_paper_status(paper_id, PaperStatus(
        paper_id=paper_id,
        status=ProcessingStatus.COMPLETED,
        total_chunks=len(chunks),
        processed_chunks=len(chunks),
        current_step="completed",
        estimated_seconds_remaining=0,
        pdf_size_bytes=pdf_size_bytes,
    ))
    logger.info("[%s] TOTAL: %.1fs (%d chunks)", paper_id, t4 - t0, len(chunks))


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
                paper_id=paper_id,
                status=ProcessingStatus.COMPLETED,
                current_step="completed",
                pdf_size_bytes=_cached_pdf_size(paper_id),
            ))
            logger.info("[%s] Already indexed — skipped", paper_id)
            return

        pdf_bytes = await _download_pdf(request.pdf_url, paper_id)
        logger.info(
            "[%s] PDF ready in %.1fs (%d KB)",
            paper_id, time.time() - t0, len(pdf_bytes) // 1024,
        )
        await _index_pdf_bytes(
            paper_id,
            pdf_bytes,
            pdf_processor,
            chunker,
            embedding_service,
            vector_store,
        )

    except Exception as exc:
        logger.error("Paper processing failed for %s: %s", paper_id, exc)
        set_paper_status(paper_id, PaperStatus(
            paper_id=paper_id,
            status=ProcessingStatus.FAILED,
            current_step="failed",
            pdf_size_bytes=_cached_pdf_size(paper_id),
            error_message=str(exc),
        ))


async def _process_uploaded_paper_task(
    paper_id: str,
    pdf_bytes: bytes,
    pdf_processor,
    chunker,
    embedding_service,
    vector_store,
) -> None:
    try:
        if vector_store.has_paper(paper_id):
            set_paper_status(paper_id, PaperStatus(
                paper_id=paper_id,
                status=ProcessingStatus.COMPLETED,
                current_step="completed",
                pdf_size_bytes=_cached_pdf_size(paper_id),
            ))
            logger.info("[%s] Uploaded PDF already indexed — skipped", paper_id)
            return

        _cache_pdf_bytes(paper_id, pdf_bytes)
        logger.info("[%s] Uploaded PDF cached (%d KB)", paper_id, len(pdf_bytes) // 1024)
        await _index_pdf_bytes(
            paper_id,
            pdf_bytes,
            pdf_processor,
            chunker,
            embedding_service,
            vector_store,
        )
    except Exception as exc:
        logger.error("Uploaded paper processing failed for %s: %s", paper_id, exc)
        set_paper_status(paper_id, PaperStatus(
            paper_id=paper_id,
            status=ProcessingStatus.FAILED,
            current_step="failed",
            pdf_size_bytes=_cached_pdf_size(paper_id),
            error_message=str(exc),
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
            paper_id=paper_id,
            status=ProcessingStatus.COMPLETED,
            current_step="completed",
            pdf_size_bytes=_cached_pdf_size(paper_id),
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

    _set_processing_status(paper_id, "queued")

    background_tasks.add_task(
        _process_paper_task,
        request,
        get_pdf_processor(),
        get_chunker(),
        get_embedding_service(),
        get_vector_store(),
    )
    return ProcessPaperResponse(paper_id=paper_id, status="processing", message="PDF processing started")


@router.post("/upload", response_model=UploadPaperResponse)
async def upload_paper(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    title: str | None = Form(default=None),
):
    filename = file.filename or "uploaded.pdf"
    if not filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported")

    pdf_bytes = await file.read()
    if not pdf_bytes:
        raise HTTPException(status_code=400, detail="Uploaded PDF is empty")

    settings = get_settings()
    max_size_bytes = settings.max_pdf_size_mb * 1024 * 1024
    if len(pdf_bytes) > max_size_bytes:
        raise HTTPException(
            status_code=413,
            detail=f"PDF exceeds the {settings.max_pdf_size_mb} MB upload limit",
        )

    paper_id = f"upload-{sha1(pdf_bytes).hexdigest()[:16]}"
    normalized_title = _uploaded_title(filename, title)
    pdf_url = f"/api/papers/{paper_id}/pdf"

    vs = get_vector_store()
    if vs.has_paper(paper_id):
        set_paper_status(paper_id, PaperStatus(
            paper_id=paper_id,
            status=ProcessingStatus.COMPLETED,
            current_step="completed",
            pdf_size_bytes=len(pdf_bytes),
        ))
        _cache_pdf_bytes(paper_id, pdf_bytes)
        return UploadPaperResponse(
            paper_id=paper_id,
            title=normalized_title,
            pdf_url=pdf_url,
            status="completed",
            message="PDF already indexed",
            pdf_size_bytes=len(pdf_bytes),
        )

    store = get_paper_status_store()
    existing = store.get(paper_id)
    if existing and existing.status == ProcessingStatus.PROCESSING:
        _cache_pdf_bytes(paper_id, pdf_bytes)
        return UploadPaperResponse(
            paper_id=paper_id,
            title=normalized_title,
            pdf_url=pdf_url,
            status="processing",
            message="PDF is already being processed",
            pdf_size_bytes=len(pdf_bytes),
        )

    _set_processing_status(paper_id, "queued")
    background_tasks.add_task(
        _process_uploaded_paper_task,
        paper_id,
        pdf_bytes,
        get_pdf_processor(),
        get_chunker(),
        get_embedding_service(),
        get_vector_store(),
    )
    return UploadPaperResponse(
        paper_id=paper_id,
        title=normalized_title,
        pdf_url=pdf_url,
        status="processing",
        message="PDF upload received and indexing started",
        pdf_size_bytes=len(pdf_bytes),
    )


@router.get("/pdf-size", response_model=PdfSizeResponse)
async def pdf_size(
    pdf_url: str = Query(..., min_length=1),
    paper_id: str | None = Query(default=None),
):
    cached_size = _cached_pdf_size(paper_id)
    if cached_size is not None:
        return PdfSizeResponse(
            paper_id=paper_id,
            pdf_url=pdf_url,
            size_bytes=cached_size,
            source="cache",
        )

    try:
        size = await _remote_pdf_size(pdf_url)
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail=f"PDF size lookup failed: {exc}") from exc

    return PdfSizeResponse(
        paper_id=paper_id,
        pdf_url=pdf_url,
        size_bytes=size,
        source="remote" if size is not None else "unknown",
    )


@router.get("/{paper_id}/status", response_model=PaperStatusResponse)
async def paper_status(paper_id: str):
    store = get_paper_status_store()
    status = store.get(paper_id)

    # Status store is in-memory and lost on restart. Fall back to the
    # persisted FAISS index so clients don't re-index papers needlessly.
    if not status:
        vs = get_vector_store()
        if vs.has_paper(paper_id):
            status = PaperStatus(
                paper_id=paper_id,
                status=ProcessingStatus.COMPLETED,
                current_step="completed",
                pdf_size_bytes=_cached_pdf_size(paper_id),
            )
            store[paper_id] = status
        else:
            raise HTTPException(status_code=404, detail=f"Paper '{paper_id}' not found")

    return PaperStatusResponse(
        paper_id=status.paper_id,
        status=status.status.value,
        total_chunks=status.total_chunks,
        processed_chunks=status.processed_chunks,
        current_step=status.current_step,
        estimated_seconds_remaining=status.estimated_seconds_remaining,
        pdf_size_bytes=status.pdf_size_bytes,
        error_message=status.error_message,
    )


@router.get("/{paper_id}/pdf")
async def get_cached_pdf(paper_id: str):
    pdf_path = _pdf_cache_path(paper_id)
    if not pdf_path.exists():
        raise HTTPException(status_code=404, detail=f"PDF for '{paper_id}' not found")
    return FileResponse(pdf_path, media_type="application/pdf", filename=f"{paper_id}.pdf")


@router.delete("/{paper_id}")
async def delete_paper(paper_id: str):
    vector_store = get_vector_store()
    store = get_paper_status_store()
    if paper_id not in store and not vector_store.has_paper(paper_id):
        raise HTTPException(status_code=404, detail=f"Paper '{paper_id}' not found")
    vector_store.remove_paper(paper_id)
    vector_store.save()
    store.pop(paper_id, None)
    pdf_path = _pdf_cache_path(paper_id)
    if pdf_path.exists():
        pdf_path.unlink()
    return {"message": f"Paper '{paper_id}' removed from index"}
