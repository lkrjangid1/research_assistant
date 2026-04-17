import logging
import pickle
from pathlib import Path
from typing import Optional

import faiss
import numpy as np

from app.core.exceptions import VectorStoreError
from app.models.chunk import SearchResult

logger = logging.getLogger(__name__)

SCORE_THRESHOLD = 0.3


class VectorStore:
    """FAISS IndexFlatIP vector store with paper-id filtering and disk persistence."""

    def __init__(self, embedding_dim: int = 768, index_path: Optional[Path] = None):
        self.embedding_dim = embedding_dim
        self.index_path = Path(index_path) if index_path else None
        self.index = faiss.IndexFlatIP(embedding_dim)
        # chunk_ids[i] corresponds to faiss row i
        self.chunk_ids: list[str] = []
        self.metadata: dict[str, dict] = {}  # chunk_id -> {paper_id, page_number, text}
        # paper_id -> list of faiss row indices (for efficient removal)
        self._paper_rows: dict[str, list[int]] = {}

    # ── Indexing ──────────────────────────────────────────────────────────────

    def add_embeddings(
        self,
        embeddings: np.ndarray,
        chunk_ids: list[str],
        metadata: list[dict],
    ) -> None:
        embeddings = embeddings.astype(np.float32)
        faiss.normalize_L2(embeddings)
        start_row = len(self.chunk_ids)
        self.index.add(embeddings)
        for i, (cid, meta) in enumerate(zip(chunk_ids, metadata)):
            row = start_row + i
            self.chunk_ids.append(cid)
            self.metadata[cid] = meta
            pid = meta["paper_id"]
            self._paper_rows.setdefault(pid, []).append(row)
        logger.info("Added %d vectors. Total: %d", len(chunk_ids), self.index.ntotal)

    # ── Search ────────────────────────────────────────────────────────────────

    def search(
        self,
        query_embedding: np.ndarray,
        paper_ids: list[str],
        top_k: int = 5,
        score_threshold: float = SCORE_THRESHOLD,
    ) -> list[SearchResult]:
        if self.index.ntotal == 0:
            return []
        query = query_embedding.reshape(1, -1).astype(np.float32)
        faiss.normalize_L2(query)
        search_k = min(top_k * 10, self.index.ntotal)
        scores, indices = self.index.search(query, search_k)

        paper_id_set = set(paper_ids)
        results: list[SearchResult] = []
        for score, idx in zip(scores[0], indices[0]):
            if idx < 0 or float(score) < score_threshold:
                continue
            cid = self.chunk_ids[idx]
            meta = self.metadata[cid]
            if meta["paper_id"] not in paper_id_set:
                continue
            results.append(SearchResult(
                chunk_id=cid,
                paper_id=meta["paper_id"],
                page_number=meta["page_number"],
                text=meta["text"],
                score=float(score),
            ))
            if len(results) >= top_k:
                break
        return results

    def search_best_for_papers(
        self,
        query_embedding: np.ndarray,
        paper_ids: list[str],
        top_k: int = 5,
    ) -> list[SearchResult]:
        """Return the top-k highest-scoring chunks for the given paper_ids
        with NO score threshold.  Used for slash commands whose synthesised
        queries may be semantically distant from raw chunk text even when the
        paper is clearly relevant."""
        if self.index.ntotal == 0:
            return []
        query = query_embedding.reshape(1, -1).astype(np.float32)
        faiss.normalize_L2(query)
        # Expand search to the full index so we don't miss paper-id matches
        search_k = self.index.ntotal
        scores, indices = self.index.search(query, search_k)

        paper_id_set = set(paper_ids)
        results: list[SearchResult] = []
        for score, idx in zip(scores[0], indices[0]):
            if idx < 0:
                continue
            cid = self.chunk_ids[idx]
            meta = self.metadata[cid]
            if meta["paper_id"] not in paper_id_set:
                continue
            results.append(SearchResult(
                chunk_id=cid,
                paper_id=meta["paper_id"],
                page_number=meta["page_number"],
                text=meta["text"],
                score=float(score),
            ))
            if len(results) >= top_k:
                break
        return results

    # ── Removal ───────────────────────────────────────────────────────────────

    def remove_paper(self, paper_id: str) -> None:
        """Remove all chunks for a paper by rebuilding the index."""
        if paper_id not in self._paper_rows:
            return
        rows_to_remove = set(self._paper_rows.pop(paper_id))
        new_chunk_ids: list[str] = []
        new_metadata: dict[str, dict] = {}
        kept_embeddings: list[np.ndarray] = []
        new_paper_rows: dict[str, list[int]] = {}

        for old_row, cid in enumerate(self.chunk_ids):
            if old_row in rows_to_remove:
                self.metadata.pop(cid, None)
                continue
            meta = self.metadata[cid]
            new_row = len(new_chunk_ids)
            new_chunk_ids.append(cid)
            new_metadata[cid] = meta
            new_paper_rows.setdefault(meta["paper_id"], []).append(new_row)
            # Reconstruct original vector from index
            vec = np.zeros((self.embedding_dim,), dtype=np.float32)
            self.index.reconstruct(old_row, vec)
            kept_embeddings.append(vec)

        self.index = faiss.IndexFlatIP(self.embedding_dim)
        if kept_embeddings:
            emb = np.stack(kept_embeddings)
            self.index.add(emb)
        self.chunk_ids = new_chunk_ids
        self.metadata = new_metadata
        self._paper_rows = new_paper_rows
        logger.info("Removed paper %s. Total vectors: %d", paper_id, self.index.ntotal)

    # ── Persistence ───────────────────────────────────────────────────────────

    def save(self) -> None:
        if not self.index_path:
            return
        self.index_path.mkdir(parents=True, exist_ok=True)
        faiss.write_index(self.index, str(self.index_path / "index.faiss"))
        with open(self.index_path / "metadata.pkl", "wb") as f:
            pickle.dump({
                "metadata": self.metadata,
                "chunk_ids": self.chunk_ids,
                "paper_rows": self._paper_rows,
            }, f)
        logger.info("VectorStore saved to %s", self.index_path)

    def load(self) -> None:
        if not self.index_path:
            return
        index_file = self.index_path / "index.faiss"
        meta_file = self.index_path / "metadata.pkl"
        if not index_file.exists():
            logger.info("No FAISS index found at %s — starting fresh", self.index_path)
            return
        loaded_index = faiss.read_index(str(index_file))
        # Dimension mismatch → embedding model changed; discard stale vectors
        if loaded_index.d != self.embedding_dim:
            logger.warning(
                "Index dimension %d != configured %d — discarding old index",
                loaded_index.d, self.embedding_dim,
            )
            return
        self.index = loaded_index
        with open(meta_file, "rb") as f:
            data = pickle.load(f)
        self.metadata = data["metadata"]
        self.chunk_ids = data["chunk_ids"]
        self._paper_rows = data.get("paper_rows", {})
        logger.info("VectorStore loaded: %d vectors", self.index.ntotal)

    # ── Helpers ───────────────────────────────────────────────────────────────

    def has_paper(self, paper_id: str) -> bool:
        return paper_id in self._paper_rows and bool(self._paper_rows[paper_id])

    @property
    def total_vectors(self) -> int:
        return self.index.ntotal
