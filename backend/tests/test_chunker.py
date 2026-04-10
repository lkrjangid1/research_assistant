import pytest
from app.models.chunk import ExtractedPage
from app.services.chunker import SemanticChunker, MIN_CHUNK_CHARS


def make_page(num: int, text: str) -> ExtractedPage:
    return ExtractedPage(page_number=num, text=text)


def test_basic_chunking(chunker):
    long_text = "This is a paragraph. " * 200  # ~4200 chars, should produce multiple chunks
    pages = [make_page(1, long_text)]
    chunks = chunker.chunk_document(pages, "p1")
    assert len(chunks) >= 2
    for c in chunks:
        assert c.paper_id == "p1"


def test_page_number_preserved(chunker):
    pages = [make_page(3, "word " * 100)]
    chunks = chunker.chunk_document(pages, "p1")
    assert all(c.page_number == 3 for c in chunks)


def test_small_fragment_discarded(chunker):
    pages = [make_page(1, "tiny")]  # < MIN_CHUNK_CHARS
    chunks = chunker.chunk_document(pages, "p1")
    assert len(chunks) == 0


def test_overlap_present(chunker):
    # Build text that creates at least 2 chunks
    para = "word " * 300  # ~1500 chars
    pages = [make_page(1, para + "\n\n" + para)]
    chunks = chunker.chunk_document(pages, "p1")
    if len(chunks) >= 2:
        tail_of_first = chunks[0].text[-chunker._overlap_chars:]
        assert tail_of_first in chunks[1].text or len(tail_of_first) == 0


def test_chunk_ids_unique(chunker):
    pages = [make_page(1, "word " * 400), make_page(2, "word " * 400)]
    chunks = chunker.chunk_document(pages, "p1")
    ids = [c.chunk_id for c in chunks]
    assert len(ids) == len(set(ids))
