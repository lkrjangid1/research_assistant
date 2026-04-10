from fastapi import HTTPException


class PDFProcessingError(Exception):
    def __init__(self, message: str, detail: dict | None = None):
        self.message = message
        self.detail = detail or {}
        super().__init__(message)


class EmbeddingError(Exception):
    def __init__(self, message: str, detail: dict | None = None):
        self.message = message
        self.detail = detail or {}
        super().__init__(message)


class VectorStoreError(Exception):
    def __init__(self, message: str, detail: dict | None = None):
        self.message = message
        self.detail = detail or {}
        super().__init__(message)


class RAGError(Exception):
    def __init__(self, message: str, detail: dict | None = None):
        self.message = message
        self.detail = detail or {}
        super().__init__(message)


class PaperNotFoundError(Exception):
    def __init__(self, paper_id: str):
        self.paper_id = paper_id
        self.message = f"Paper '{paper_id}' not found in index"
        super().__init__(self.message)


class RateLimitExceededError(Exception):
    def __init__(self, message: str = "Rate limit exceeded"):
        self.message = message
        super().__init__(message)


def to_http_exception(exc: Exception) -> HTTPException:
    if isinstance(exc, PaperNotFoundError):
        return HTTPException(status_code=404, detail=exc.message)
    if isinstance(exc, RateLimitExceededError):
        return HTTPException(status_code=429, detail=exc.message)
    if isinstance(exc, PDFProcessingError):
        return HTTPException(status_code=400, detail=exc.message)
    if isinstance(exc, (EmbeddingError, VectorStoreError, RAGError)):
        return HTTPException(status_code=500, detail=str(exc))
    return HTTPException(status_code=500, detail="Internal server error")


def register_exception_handlers(app) -> None:
    from fastapi.responses import JSONResponse

    @app.exception_handler(PDFProcessingError)
    async def pdf_error_handler(request, exc):
        return JSONResponse(status_code=400, content={"detail": exc.message})

    @app.exception_handler(PaperNotFoundError)
    async def not_found_handler(request, exc):
        return JSONResponse(status_code=404, content={"detail": exc.message})

    @app.exception_handler(RAGError)
    async def rag_error_handler(request, exc):
        return JSONResponse(status_code=500, content={"detail": exc.message})
