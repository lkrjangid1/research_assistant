import logging
from app.models.chunk import SearchResult
from app.models.chat import Citation, RAGResponse
from app.services.vector_store import VectorStore
from app.services.embedding_service import EmbeddingService
from app.services.vertex_ai_client import VertexAIClient

logger = logging.getLogger(__name__)

_VALID_COMMANDS = {"summary", "compare", "review", "gaps", "code", "visualize", "search", "explain"}


class RAGService:
    """Retrieval Augmented Generation pipeline."""

    def __init__(
        self,
        vector_store: VectorStore,
        embedding_service: EmbeddingService,
        llm_client: VertexAIClient,
        top_k: int = 5,
    ):
        self.vector_store = vector_store
        self.embedding_service = embedding_service
        self.llm_client = llm_client
        self.top_k = top_k

    # ── Main query ────────────────────────────────────────────────────────────

    async def query(
        self,
        question: str,
        paper_ids: list[str],
        paper_titles: dict[str, str],
    ) -> RAGResponse:
        query_embedding = await self.embedding_service.embed_query(question)
        results = self.vector_store.search(query_embedding, paper_ids, self.top_k)

        if not results:
            return RAGResponse(
                text="I couldn't find relevant information in the selected papers to answer your question.",
                citations=[],
            )

        context = self._build_context(results, paper_titles)
        prompt = self._build_prompt(question, context)
        response_text = await self.llm_client.generate(prompt)
        citations = self._extract_citations(results, paper_titles)
        return RAGResponse(text=response_text, citations=citations)

    # ── Slash commands ────────────────────────────────────────────────────────

    async def execute_command(
        self,
        command: str,
        args: str | None,
        paper_ids: list[str],
        paper_titles: dict[str, str],
    ) -> RAGResponse:
        cmd = command.lstrip("/").lower()
        if cmd not in _VALID_COMMANDS:
            return RAGResponse(text=f"Unknown command: /{cmd}", citations=[])

        if cmd == "search":
            return await self.query(args or "", paper_ids, paper_titles)

        if cmd == "summary":
            level = (args or "intermediate").strip()
            question = f"Generate a {level}-level summary of the paper."
        elif cmd == "compare":
            question = (
                "Compare the methodologies, contributions, and findings across all selected papers. "
                "Highlight similarities and differences."
            )
        elif cmd == "review":
            focus = (args or "full").strip()
            question = f"Generate a literature review focusing on {focus} aspects of the selected papers."
        elif cmd == "gaps":
            question = (
                "Identify the research gaps and open problems mentioned or implied in the selected papers."
            )
        elif cmd == "code":
            lang = (args or "Python").strip()
            question = (
                f"Describe how to implement the core algorithm from the selected papers in {lang}. "
                "Provide pseudocode or implementation guidance."
            )
        elif cmd == "visualize":
            vis_type = (args or "architecture").strip()
            question = (
                f"Describe how to create a {vis_type} visualization of the key concepts in the selected papers."
            )
        elif cmd == "explain":
            term = (args or "").strip()
            question = f"Explain the concept '{term}' as described in the selected papers."
        else:
            question = f"Help me understand the selected papers regarding: {args or 'general overview'}."

        return await self.query(question, paper_ids, paper_titles)

    # ── Helpers ───────────────────────────────────────────────────────────────

    def _build_context(self, results: list[SearchResult], paper_titles: dict[str, str]) -> str:
        parts = []
        for i, r in enumerate(results, 1):
            title = paper_titles.get(r.paper_id, r.paper_id)
            parts.append(f'[{i}] From "{title}" (Page {r.page_number}):\n{r.text}')
        return "\n\n".join(parts)

    def _build_prompt(self, question: str, context: str) -> str:
        return (
            "You are a research assistant helping answer questions about academic papers.\n"
            "Use ONLY the provided context to answer the question. "
            "If the context doesn't contain enough information, say so.\n"
            "Always cite your sources using [Paper Title, Page N] format inline in your response.\n\n"
            f"CONTEXT:\n{context}\n\n"
            f"QUESTION: {question}\n\n"
            "ANSWER (with inline citations):"
        )

    def _extract_citations(
        self, results: list[SearchResult], paper_titles: dict[str, str]
    ) -> list[Citation]:
        seen: set[tuple] = set()
        citations: list[Citation] = []
        for r in results:
            key = (r.paper_id, r.page_number)
            if key not in seen:
                seen.add(key)
                citations.append(Citation(
                    paper_title=paper_titles.get(r.paper_id, r.paper_id),
                    page_number=r.page_number,
                    excerpt=r.text[:200] + "..." if len(r.text) > 200 else r.text,
                ))
        return citations
