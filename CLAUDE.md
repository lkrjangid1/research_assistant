# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI-powered mobile app for searching, summarizing, and chatting with academic research papers using RAG (Retrieval Augmented Generation). The full technical specification lives in `TRD.md`.

## Architecture

Three-tier system:

1. **Flutter Mobile App** — search UI, paper details, chat interface, local-first storage
2. **FastAPI Backend** — PDF processing, embedding generation, RAG orchestration
3. **External Services** — arXiv API (paper discovery), Google Vertex AI (Gemini 1.5 Pro + text-embedding-004), FAISS (vector store)

### Flutter App (`lib/`)

- **State management**: Bloc/Cubit pattern — one Cubit per feature (SearchCubit, ChatCubit, PaperDetailsCubit, PaperSelectionCubit, SettingsCubit)
- **DI**: GetIt (`core/di/injection_container.dart`)
- **Local storage**: Hive with TypeAdapters (typeId 0–3 for Paper, ChatSession, Message, Citation)
- **HTTP**: Dio client (`core/network/api_client.dart`)
- **Architecture layers**: `domain/` (entities + abstract repos + use cases) → `data/` (models + repo impls + datasources) → `presentation/` (cubits + pages)
- **arXiv XML parsing**: handled in `core/utils/xml_parser.dart`, not by the backend

### Backend (`backend/`)

- **Entry**: `main.py` → `app/api/routes/` (papers, chat, health)
- **RAG pipeline** (in order): `pdf_processor.py` → `chunker.py` → `embedding_service.py` → `vector_store.py` → `rag_service.py`
- **Chunking**: 512-token chunks, 50-token overlap, paragraph-aware, page numbers preserved for citations
- **Embeddings**: `text-embedding-004`, 768-dim, normalized for cosine similarity via FAISS `IndexFlatIP`
- **Generation**: Gemini 1.5 Pro, temperature 0.3, max 2048 output tokens
- **FAISS index** is in-memory with disk persistence (`index.faiss` + `metadata.pkl`)

### Key Design Constraints

- Chat history is **local-only** (Hive on device) — never sent to backend
- Maximum **3 papers** per chat session (`PaperSelectionCubit.maxPapers = 3`)
- FAISS search expands `top_k * 10` before filtering by `paper_ids`
- arXiv API: 1 req/3 sec rate limit, no auth required; use exponential backoff on 503
- PDF max size: 50 MB; chunk storage ~100 chunks/paper

## Backend Commands

```bash
cd backend
pip install -r requirements.txt

# Run dev server
uvicorn main:app --reload --port 8000

# Run tests
pytest tests/
pytest tests/test_rag_service.py          # single test file
pytest tests/test_api_endpoints.py -k "test_chat_query"  # single test

# Seed test data
python scripts/seed_test_data.py
```

Environment variables required (copy from `.env.example`):
```
VERTEX_PROJECT_ID=your-project-id
VERTEX_LOCATION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
GEMINI_MODEL=gemini-1.5-pro
EMBEDDING_MODEL=text-embedding-004
```

## Flutter Commands

```bash
# Get dependencies
flutter pub get

# Generate Hive TypeAdapters (run after modifying @HiveType models)
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Run tests
flutter test
flutter test test/cubits/search_cubit_test.dart  # single test file

# Analyze
flutter analyze
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/chat/query` | RAG chat query (1–3 paper_ids) |
| POST | `/api/chat/command` | Slash command (`/summary`, `/compare`, `/gaps`, etc.) |
| POST | `/api/papers/process` | Upload PDF for indexing |
| GET | `/api/papers/{id}/status` | Processing status |
| POST | `/api/summary/generate` | Adaptive summary (beginner/intermediate/expert) |
| GET | `/health` | Health check |

## Slash Commands

`/summary [level]`, `/compare`, `/review [focus]`, `/gaps`, `/code [lang]`, `/visualize [type]`, `/search <query>`, `/explain <term>`

All slash commands are detected in `ChatCubit.sendMessage()` when content starts with `/` and routed to `ProcessSlashCommandUseCase`.

## Hive TypeAdapter IDs

| typeId | Model |
|--------|-------|
| 0 | PaperModel |
| 1 | ChatSessionModel |
| 2 | MessageModel |
| 3 | CitationModel |

Do not reuse or reorder these IDs — Hive uses them for deserialization of persisted data.

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** The graph is faster, cheaper (fewer tokens), and gives
you structural context (callers, dependents, test coverage) that file
scanning cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes` or `query_graph` instead of Grep
- **Understanding impact**: `get_impact_radius` instead of manually tracing imports
- **Code review**: `detect_changes` + `get_review_context` instead of reading entire files
- **Finding relationships**: `query_graph` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview` + `list_communities`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
|------|----------|
| `detect_changes` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context` | Need source snippets for review — token-efficient |
| `get_impact_radius` | Understanding blast radius of a change |
| `get_affected_flows` | Finding which execution paths are impacted |
| `query_graph` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes` | Finding functions/classes by name or keyword |
| `get_architecture_overview` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes` for code review.
3. Use `get_affected_flows` to understand impact.
4. Use `query_graph` pattern="tests_for" to check coverage.
