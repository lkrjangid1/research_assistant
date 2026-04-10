from dataclasses import dataclass, field


@dataclass
class ExtractedPage:
    page_number: int
    text: str


@dataclass
class ProcessedDocument:
    paper_id: str
    pages: list[ExtractedPage]
    total_pages: int


@dataclass
class Chunk:
    text: str
    paper_id: str
    page_number: int
    chunk_index: int
    start_char: int
    end_char: int

    @property
    def chunk_id(self) -> str:
        return f"{self.paper_id}_chunk_{self.chunk_index}"


@dataclass
class SearchResult:
    chunk_id: str
    paper_id: str
    page_number: int
    text: str
    score: float
