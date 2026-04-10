import numpy as np
import pytest
from app.services.vector_store import VectorStore


def make_store(tmp_path):
    return VectorStore(embedding_dim=4, index_path=tmp_path / "idx")


def random_emb(n=1, dim=4):
    e = np.random.rand(n, dim).astype(np.float32)
    return e / np.linalg.norm(e, axis=1, keepdims=True)


def test_add_and_search(tmp_path):
    vs = make_store(tmp_path)
    embs = random_emb(3, 4)
    vs.add_embeddings(embs, ["p1_chunk_0", "p1_chunk_1", "p1_chunk_2"],
                      [{"paper_id": "p1", "page_number": 1, "text": f"text{i}"} for i in range(3)])
    results = vs.search(embs[0], ["p1"], top_k=2, score_threshold=0.0)
    assert len(results) >= 1
    assert results[0].paper_id == "p1"


def test_paper_id_filtering(tmp_path):
    vs = make_store(tmp_path)
    e1 = random_emb(2, 4)
    e2 = random_emb(2, 4)
    vs.add_embeddings(e1, ["a_0", "a_1"], [{"paper_id": "a", "page_number": 1, "text": "a"}, {"paper_id": "a", "page_number": 2, "text": "a2"}])
    vs.add_embeddings(e2, ["b_0", "b_1"], [{"paper_id": "b", "page_number": 1, "text": "b"}, {"paper_id": "b", "page_number": 2, "text": "b2"}])
    results = vs.search(e1[0], ["a"], top_k=5, score_threshold=0.0)
    assert all(r.paper_id == "a" for r in results)


def test_score_threshold(tmp_path):
    vs = make_store(tmp_path)
    e = random_emb(1, 4)
    vs.add_embeddings(e, ["p_0"], [{"paper_id": "p", "page_number": 1, "text": "text"}])
    results = vs.search(e[0], ["p"], top_k=5, score_threshold=2.0)  # impossibly high threshold
    assert len(results) == 0


def test_save_and_load(tmp_path):
    vs = make_store(tmp_path)
    e = random_emb(2, 4)
    vs.add_embeddings(e, ["x_0", "x_1"], [{"paper_id": "x", "page_number": i, "text": f"t{i}"} for i in range(2)])
    vs.save()
    vs2 = make_store(tmp_path)
    vs2.load()
    assert vs2.total_vectors == 2
    results = vs2.search(e[0], ["x"], top_k=1, score_threshold=0.0)
    assert len(results) == 1


def test_remove_paper(tmp_path):
    vs = make_store(tmp_path)
    e = random_emb(3, 4)
    vs.add_embeddings(e[:2], ["a_0", "a_1"], [{"paper_id": "a", "page_number": 1, "text": "t"}, {"paper_id": "a", "page_number": 2, "text": "t2"}])
    vs.add_embeddings(e[2:], ["b_0"], [{"paper_id": "b", "page_number": 1, "text": "tb"}])
    vs.remove_paper("a")
    assert not vs.has_paper("a")
    assert vs.has_paper("b")
    results = vs.search(e[0], ["a"], top_k=5, score_threshold=0.0)
    assert len(results) == 0


def test_empty_search(tmp_path):
    vs = make_store(tmp_path)
    q = random_emb(1, 4)[0]
    results = vs.search(q, ["any"], top_k=5)
    assert results == []
