import asyncio
import re
import logging
from app.models.chunk import ExtractedPage, ProcessedDocument

logger = logging.getLogger(__name__)


class PDFProcessor:
    """Extract text from research paper PDFs with page mapping."""

    def __init__(self, min_text_length: int = 50):
        self.min_text_length = min_text_length

    async def process_pdf(self, pdf_bytes: bytes, paper_id: str) -> ProcessedDocument:
        """Extract text from PDF bytes, maintaining 1-indexed page numbers."""
        return await asyncio.to_thread(self._process_sync, pdf_bytes, paper_id)

    def _process_sync(self, pdf_bytes: bytes, paper_id: str) -> ProcessedDocument:
        import fitz  # PyMuPDF
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        pages: list[ExtractedPage] = []

        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            text = page.get_text("text")
            text = self._clean_text(text)
            if len(text) >= self.min_text_length:
                pages.append(ExtractedPage(page_number=page_num + 1, text=text))

        total = len(doc)
        doc.close()
        logger.info("Processed PDF %s: %d/%d pages extracted", paper_id, len(pages), total)
        return ProcessedDocument(paper_id=paper_id, pages=pages, total_pages=total)

    def _clean_text(self, text: str) -> str:
        # Fix hyphenated line breaks (word-\n → word)
        text = re.sub(r"-\n", "", text)
        # Collapse all whitespace runs to single space
        text = re.sub(r"[ \t]+", " ", text)
        # Normalise line endings
        text = re.sub(r"\n{3,}", "\n\n", text)
        # Strip null bytes and replacement chars
        text = text.replace("\x00", "").replace("\ufffd", "")
        return text.strip()
