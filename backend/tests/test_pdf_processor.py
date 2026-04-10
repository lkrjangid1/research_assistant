import pytest


def test_process_valid_pdf(pdf_processor, sample_pdf_bytes):
    import asyncio
    doc = asyncio.run(pdf_processor.process_pdf(sample_pdf_bytes, "test_paper"))
    assert doc.paper_id == "test_paper"
    assert len(doc.pages) >= 1
    assert doc.pages[0].page_number == 1  # 1-indexed


def test_skips_short_pages(pdf_processor):
    import fitz, asyncio
    d = fitz.open()
    p = d.new_page()
    p.insert_text((72, 72), "Hi")  # very short
    p2 = d.new_page()
    p2.insert_text((72, 72), "This is a sufficiently long paragraph with meaningful content for testing purposes.")
    pdf_bytes = d.tobytes()
    d.close()
    doc = asyncio.run(pdf_processor.process_pdf(pdf_bytes, "p"))
    assert all(len(page.text) >= pdf_processor.min_text_length for page in doc.pages)


def test_clean_text_removes_hyphenation(pdf_processor):
    text = "deep learn-\ning is great"
    result = pdf_processor._clean_text(text)
    assert "learning" in result
    assert "-\n" not in result


def test_empty_pdf_returns_zero_pages(pdf_processor):
    import fitz, asyncio
    d = fitz.open()
    pdf_bytes = d.tobytes()
    d.close()
    doc = asyncio.run(pdf_processor.process_pdf(pdf_bytes, "empty"))
    assert len(doc.pages) == 0
    assert doc.total_pages == 0
