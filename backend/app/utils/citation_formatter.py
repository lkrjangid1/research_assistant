import re


def format_citation(paper_title: str, page_number: int) -> str:
    return f"[{paper_title}, Page {page_number}]"


def extract_citations_from_text(text: str) -> list[dict]:
    """Parse [Paper Title, Page N] patterns from LLM output."""
    pattern = r"\[([^\]]+),\s*Page\s+(\d+)\]"
    results = []
    for match in re.finditer(pattern, text):
        results.append({"paper_title": match.group(1).strip(), "page_number": int(match.group(2))})
    return results
