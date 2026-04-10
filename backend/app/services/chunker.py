import logging
from app.models.chunk import ExtractedPage, Chunk

logger = logging.getLogger(__name__)

MIN_CHUNK_CHARS = 100


class SemanticChunker:
    """Chunk documents with paragraph-aware boundaries and overlap.

    Preserves page number mapping for citation generation.
    """

    def __init__(
        self,
        chunk_size: int = 512,       # tokens
        chunk_overlap: int = 50,      # tokens
        separator: str = "\n\n",
        chars_per_token: int = 4,
    ):
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        self.separator = separator
        self.chars_per_token = chars_per_token
        self._max_chars = chunk_size * chars_per_token          # 2048
        self._overlap_chars = chunk_overlap * chars_per_token   # 200

    def chunk_document(self, pages: list[ExtractedPage], paper_id: str) -> list[Chunk]:
        """Create overlapping chunks from extracted pages."""
        chunks: list[Chunk] = []
        chunk_index = 0
        current_text = ""
        current_page = 1

        for page in pages:
            paragraphs = page.text.split(self.separator)
            for para in paragraphs:
                para = para.strip()
                if not para:
                    continue

                if len(current_text) + len(para) + 1 <= self._max_chars:
                    current_text = (current_text + " " + para).strip() if current_text else para
                    current_page = page.page_number
                else:
                    # Emit current buffer
                    if len(current_text) >= MIN_CHUNK_CHARS:
                        chunks.append(Chunk(
                            text=current_text,
                            paper_id=paper_id,
                            page_number=current_page,
                            chunk_index=chunk_index,
                            start_char=0,
                            end_char=len(current_text),
                        ))
                        chunk_index += 1

                    # Overlap from tail of current buffer
                    overlap = current_text[-self._overlap_chars:] if self._overlap_chars else ""
                    current_text = (overlap + " " + para).strip() if overlap else para
                    current_page = page.page_number

        # Flush last buffer
        if len(current_text) >= MIN_CHUNK_CHARS:
            chunks.append(Chunk(
                text=current_text,
                paper_id=paper_id,
                page_number=current_page,
                chunk_index=chunk_index,
                start_char=0,
                end_char=len(current_text),
            ))

        logger.info("Chunked %s: %d chunks", paper_id, len(chunks))
        return chunks
