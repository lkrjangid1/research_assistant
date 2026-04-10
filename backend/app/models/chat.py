from dataclasses import dataclass, field


@dataclass
class Citation:
    paper_title: str
    page_number: int
    excerpt: str


@dataclass
class RAGResponse:
    text: str
    citations: list[Citation] = field(default_factory=list)
