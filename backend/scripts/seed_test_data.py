"""Smoke-test script: processes a real arXiv paper and runs a test query.

Usage:
    cd backend
    python scripts/seed_test_data.py
"""
import asyncio
import httpx
import time

BASE_URL = "http://localhost:8000"
TEST_PAPER = {
    "paper_id": "1706.03762",
    "title": "Attention Is All You Need",
    "authors": ["Ashish Vaswani", "Noam Shazeer"],
    "pdf_url": "https://arxiv.org/pdf/1706.03762.pdf",
}


async def main():
    async with httpx.AsyncClient(base_url=BASE_URL, timeout=120.0) as client:
        # Health check
        r = await client.get("/health")
        assert r.status_code == 200, f"Health check failed: {r.text}"
        print("✓ Health check passed")

        # Process paper
        r = await client.post("/api/papers/process", json=TEST_PAPER)
        assert r.status_code == 200, f"Process failed: {r.text}"
        print(f"✓ Processing started: {r.json()}")

        # Poll status
        paper_id = TEST_PAPER["paper_id"]
        for _ in range(60):
            await asyncio.sleep(5)
            r = await client.get(f"/api/papers/{paper_id}/status")
            status = r.json()["status"]
            print(f"  Status: {status}")
            if status == "completed":
                print(f"✓ Processed {r.json()['total_chunks']} chunks")
                break
            if status == "failed":
                print(f"✗ Processing failed: {r.json()['error_message']}")
                return
        else:
            print("✗ Timed out waiting for processing")
            return

        # Test query
        r = await client.post("/api/chat/query", json={
            "question": "What is the transformer architecture?",
            "paper_ids": [paper_id],
            "paper_titles": {paper_id: TEST_PAPER["title"]},
        })
        assert r.status_code == 200, f"Query failed: {r.text}"
        data = r.json()
        print(f"\n✓ RAG Response:\n{data['text'][:500]}")
        print(f"\n✓ Citations: {data['citations']}")


if __name__ == "__main__":
    asyncio.run(main())
