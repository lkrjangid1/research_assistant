# Research Assistant

AI-powered research paper assistant built as a three-tier system: a Flutter mobile app for search and chat, a FastAPI backend for PDF indexing and RAG orchestration, and external AI/search infrastructure such as arXiv, Google Gemini/Vertex AI-style services, and FAISS.

The app lets a user search arXiv, inspect paper details, generate expertise-aware summaries, select up to three papers, and ask citation-grounded questions over the indexed PDFs.

## Architecture Overview

```text
Flutter Mobile App
  ├─ Search papers from arXiv
  ├─ Show paper details and summaries
  ├─ Manage selected papers and chat sessions
  └─ Persist settings/chat history locally with Hive
            |
            | HTTP / JSON
            v
FastAPI Backend
  ├─ Download PDFs in the background
  ├─ Extract and clean PDF text
  ├─ Chunk text with page-number preservation
  ├─ Generate embeddings
  ├─ Store/search chunks in FAISS
  ├─ Run RAG queries and slash commands
  └─ Generate adaptive summaries
            |
            +--> arXiv API for paper discovery
            +--> Google Gemini / Vertex AI-style generation + embeddings
            +--> FAISS persistent vector index on disk
```

### Tier Responsibilities

| Tier | Technology | Responsibility |
| --- | --- | --- |
| Mobile client | Flutter, Bloc/Cubit, GetIt, Hive, Dio | UI, app state, local persistence, arXiv search, backend API consumption |
| Backend | FastAPI, PyMuPDF, FAISS, httpx | PDF ingestion, chunking, embeddings, retrieval, summarization, chat orchestration |
| External services | arXiv, Google Gemini/Vertex AI, FAISS storage | Paper discovery, LLM generation, embeddings, vector similarity search |

> Note
> The design docs and class naming refer to Vertex AI, but the committed backend currently reads `GEMINI_API_KEY` from `backend/.env` and calls the Gemini REST endpoints directly. Keep Google Cloud / service-account prerequisites if you plan to migrate to a full Vertex AI auth flow, but the current code path requires the API key.

## Main User Flow

1. The Flutter app searches arXiv directly and parses the Atom/XML response into `Paper` entities.
2. When a user selects a paper, the app calls `POST /api/papers/process`.
3. The backend downloads the paper PDF in a `BackgroundTasks` job, extracts text, chunks it, embeds it, and stores vectors in FAISS.
4. Once selected papers finish indexing, the user can open chat and ask free-form questions or slash commands.
5. The backend embeds the query, retrieves relevant chunks from FAISS, builds a citation-aware prompt, and asks Gemini for a grounded answer.
6. Chat sessions stay local on the device in Hive; the backend only receives the current query, selected paper IDs/titles, and session ID.

## Project Structure

Generated folders such as `build/`, `.dart_tool/`, `.venv/`, and `.code-review-graph/` are omitted below.

```text
.
├── AGENTS.md                          # Repo-specific agent instructions
├── CLAUDE.md                          # Concise architecture and workflow notes
├── GEMINI.md                          # Additional AI-assistant notes
├── PLAN.md                            # Implementation plan used to scaffold the app
├── TRD.md                             # Full technical requirements document
├── analysis_options.yaml              # Dart/Flutter lint configuration
├── pubspec.yaml                       # Flutter package manifest and dependencies
├── lib/                               # Flutter application source
│   ├── main.dart                      # Flutter entry point, Hive init, adapter registration
│   ├── app/                           # App shell and route table
│   ├── core/                          # Shared constants, DI, networking, theme, utilities
│   ├── data/                          # Datasources, Hive models, repository implementations
│   ├── domain/                        # Entities, abstract repositories, use cases
│   └── presentation/                  # Cubits, pages, and reusable widgets
├── test/                              # Flutter test suite
├── backend/                           # FastAPI backend
│   ├── main.py                        # FastAPI entry point and router registration
│   ├── requirements.txt               # Python backend dependencies
│   ├── Dockerfile                     # Container image for backend service
│   ├── app/                           # Backend application package
│   │   ├── api/                       # FastAPI routes and dependency providers
│   │   ├── core/                      # Middleware and exception handling
│   │   ├── models/                    # Request/response schemas and internal models
│   │   ├── services/                  # PDF, chunking, embeddings, RAG, summary services
│   │   └── utils/                     # Backend utility helpers
│   ├── data/faiss_index/              # Persisted FAISS index and metadata
│   ├── scripts/seed_test_data.py      # Smoke-test script that indexes a real arXiv paper
│   └── tests/                         # Pytest suite for backend services and API routes
├── android/                           # Flutter Android host app
├── ios/                               # Flutter iOS host app
├── linux/                             # Flutter Linux host app
├── macos/                             # Flutter macOS host app
├── web/                               # Flutter web shell assets
├── windows/                           # Flutter Windows host app
└── README.md                          # Project documentation
```

## Flutter App Responsibilities

### Layer-by-Layer Breakdown

| Layer | Key folders | Responsibility |
| --- | --- | --- |
| Presentation | `lib/presentation/` | Screens, widgets, and Cubits that react to user input and update UI state |
| Domain | `lib/domain/` | Pure business contracts: entities, repository interfaces, and use cases |
| Data | `lib/data/` | Remote/local datasources, Hive models, repository implementations |
| Core | `lib/core/` | Constants, dependency injection, Dio clients, exceptions, interceptors, theme, utilities |

### Cubits

| Cubit | Responsibility |
| --- | --- |
| `SearchCubit` | Executes arXiv search, manages loading/error state, and paginates results |
| `PaperSelectionCubit` | Enforces the max-3-paper rule, triggers backend indexing, and polls processing status |
| `PaperDetailsCubit` | Loads a paper into state and requests an expertise-level summary |
| `ChatCubit` | Creates chat sessions, routes normal messages vs slash commands, stores local session history |
| `SettingsCubit` | Persists expertise level, dark mode, and clearing local Hive data |

### Repositories

| Repository | Implementation | Responsibility |
| --- | --- | --- |
| `PaperRepository` | `PaperRepositoryImpl` | Search arXiv, trigger backend PDF processing, poll paper status, request summaries |
| `ChatRepository` | `ChatRepositoryImpl` | Send chat queries/slash commands to backend and persist sessions locally in Hive |

### Use Cases

| Use case | Responsibility |
| --- | --- |
| `SearchPapers` | Delegates search parameters to `PaperRepository.searchPapers()` |
| `GetPaperSummary` | Delegates summary generation to `PaperRepository.getSummary()` |
| `SendChatMessage` | Delegates RAG chat queries to `ChatRepository.sendChatQuery()` |
| `ProcessSlashCommand` | Validates supported slash commands, extracts arguments, then delegates to `ChatRepository.executeSlashCommand()` |

### Why the Flutter Layers Matter

| Component | Why it exists |
| --- | --- |
| Domain entities | Keep UI and transport formats decoupled |
| Repository interfaces | Allow Cubits/use cases to ignore concrete transport and storage details |
| Datasources | Separate arXiv XML, backend JSON, and Hive persistence concerns |
| GetIt DI container | Centralizes all object creation and keeps widget trees clean |
| Two Dio clients | One client is tuned for backend JSON traffic; the other is tuned for arXiv XML and rate limiting |

## Backend Responsibilities

### API Layer

| File/folder | Responsibility |
| --- | --- |
| `backend/main.py` | Creates the FastAPI app, loads/saves the FAISS index on startup/shutdown, and mounts routers |
| `backend/app/api/routes/health.py` | Health and readiness endpoints |
| `backend/app/api/routes/papers.py` | PDF processing trigger, processing status lookup, paper removal |
| `backend/app/api/routes/chat.py` | RAG question answering and slash-command execution |
| `backend/app/api/routes/summary.py` | Adaptive summary generation |
| `backend/app/api/dependencies.py` | Singleton factories for services and in-memory paper status storage |

### RAG Pipeline

| Step | File | Responsibility |
| --- | --- | --- |
| 1. PDF fetch | `backend/app/api/routes/papers.py` | Downloads the PDF from the provided arXiv URL in a background task |
| 2. Text extraction | `backend/app/services/pdf_processor.py` | Extracts page text with PyMuPDF and cleans PDF artifacts |
| 3. Chunking | `backend/app/services/chunker.py` | Creates paragraph-aware chunks with overlap while preserving page numbers |
| 4. Embeddings | `backend/app/services/embedding_service.py` | Sends chunk/query text to the Gemini embedding endpoint and returns 768-dim vectors |
| 5. Vector index | `backend/app/services/vector_store.py` | Normalizes embeddings, stores them in FAISS, filters searches by `paper_id`, persists index to disk |
| 6. Retrieval + prompting | `backend/app/services/rag_service.py` | Embeds the question, retrieves top chunks, builds prompt context, and extracts citations |
| 7. Generation | `backend/app/services/vertex_ai_client.py` | Calls the Gemini text generation endpoint and returns the answer text |
| 8. Adaptive summary | `backend/app/services/summarizer.py` | Builds beginner/intermediate/expert summary prompts and parses key points |

### Processing and Query Paths

#### Paper indexing path

1. `POST /api/papers/process` marks the paper as `processing`.
2. FastAPI schedules `_process_paper_task()` with `BackgroundTasks`.
3. The backend downloads the PDF bytes with `httpx`.
4. `PDFProcessor` extracts text page by page.
5. `SemanticChunker` builds overlapping chunks.
6. `EmbeddingService` embeds each chunk.
7. `VectorStore` adds embeddings and persists them to `backend/data/faiss_index/`.
8. The in-memory paper status store is updated to `completed` or `failed`.

#### Chat/query path

1. `POST /api/chat/query` or `POST /api/chat/command` receives the question/command and selected paper IDs.
2. `RAGService` embeds the query text.
3. FAISS returns the highest-scoring chunks filtered to the selected papers.
4. The backend builds a prompt that explicitly asks for inline citations.
5. Gemini generates the answer.
6. The backend returns response text plus extracted citations.

## Prerequisites

### Required

- Flutter SDK `3.19+`
- Dart SDK `3.3+`
- Python `3.10+`
- `pip` and a virtual environment tool
- Internet access to arXiv and Google AI endpoints
- A Google Cloud account with Vertex AI enabled if you want to align with the project’s original architecture docs
- Service account credentials if you plan to move the backend to true Vertex AI / Google Cloud auth
- A Gemini API key for the current checked-in backend implementation

### Current Backend Environment Variables

The current backend code reads these values from `backend/.env`:

| Variable | Purpose |
| --- | --- |
| `GEMINI_API_KEY` | Required today for generation and embeddings |
| `GEMINI_MODEL` | Text generation model name |
| `EMBEDDING_MODEL` | Embedding model name |
| `FAISS_INDEX_PATH` | Location of persisted FAISS files |
| `DEBUG` | Backend debug toggle |
| `CORS_ORIGINS` | Comma-separated list of allowed origins |
| `MAX_PDF_SIZE_MB` | Configured PDF size limit |
| `RATE_LIMIT` | Intended rate-limit setting |

## Running the Backend

### 1. Install dependencies

```bash
cd backend
python3.10 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Create `backend/.env`

Create a `.env` file inside `backend/`:

```env
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-2.5-flash-lite
EMBEDDING_MODEL=gemini-embedding-001
FAISS_INDEX_PATH=./data/faiss_index
DEBUG=true
CORS_ORIGINS=*
MAX_PDF_SIZE_MB=50
RATE_LIMIT=100/minute

# Optional if you later switch to a full Vertex AI / service-account setup
GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/service-account.json
VERTEX_PROJECT_ID=your-gcp-project-id
VERTEX_LOCATION=us-central1
```

### 3. Start the FastAPI server

```bash
cd backend
source .venv/bin/activate
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Once the server is running:

- Swagger docs: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- Health check: `http://localhost:8000/health`

### 4. Seed smoke-test data

With the backend still running, seed a real arXiv paper and run a sample RAG query:

```bash
cd backend
source .venv/bin/activate
python scripts/seed_test_data.py
```

What the seed script does:

1. Calls `/health`
2. Starts processing `Attention Is All You Need`
3. Polls `/api/papers/{paper_id}/status`
4. Sends a sample `/api/chat/query`

The FAISS index is persisted under `backend/data/faiss_index/` as:

- `index.faiss`
- `metadata.pkl`

## Running the Flutter App

### 1. Install Flutter dependencies

Run this from the project root:

```bash
flutter pub get
```

### 2. Generate Hive adapters

Run this any time you change a `@HiveType` model in `lib/data/models/`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 3. Configure `BACKEND_URL`

The Flutter app reads the backend base URL from a compile-time define in `lib/core/constants/api_constants.dart`.

Examples:

- Android emulator: `http://10.0.2.2:8000`
- iOS simulator / macOS / web: `http://127.0.0.1:8000`
- Physical device: `http://<your-lan-ip>:8000`

Run with an explicit backend URL:

```bash
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8000
```

If you do not pass a value, the default is Android-emulator friendly:

```text
http://10.0.2.2:8000
```

### 4. Start the app

```bash
flutter run
```

Behavior to expect:

- Search requests go directly from Flutter to arXiv.
- Paper processing, summary generation, and chat requests go from Flutter to the FastAPI backend.
- Chat sessions and settings are stored locally in Hive.

## API Endpoints

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/` | Redirects to Swagger docs |
| `GET` | `/health` | Basic health endpoint |
| `GET` | `/health/ready` | Readiness endpoint with FAISS/AI-service flags |
| `POST` | `/api/papers/process` | Starts background PDF download, extraction, chunking, embedding, and indexing |
| `GET` | `/api/papers/{paper_id}/status` | Returns processing status for a paper |
| `DELETE` | `/api/papers/{paper_id}` | Removes a paper’s vectors from the FAISS index |
| `POST` | `/api/chat/query` | Runs a RAG question over 1 to 3 selected papers |
| `POST` | `/api/chat/command` | Executes a slash command over the selected papers |
| `POST` | `/api/summary/generate` | Generates an adaptive summary for supplied paper content |

## Slash Commands

The Flutter app validates these commands in `ProcessSlashCommand`, and the backend resolves them in `RAGService.execute_command()`.

| Command | Args | What it does |
| --- | --- | --- |
| `/summary` | `[beginner|intermediate|expert]` | Asks for a level-specific summary of the selected paper set |
| `/compare` | optional free text | Compares methodologies, contributions, and findings across selected papers |
| `/gaps` | none | Identifies research gaps and open problems |
| `/review` | `[focus]` | Produces a literature-review or critique-style answer |
| `/code` | `[language]` | Describes how to implement the core method in code or pseudocode |
| `/visualize` | `[type]` | Suggests a chart/diagram/architecture visualization |
| `/search` | `<query>` | Re-runs the query flow using the provided text against the selected papers |
| `/explain` | `<term>` | Explains a concept using the selected papers as context |

## Key Design Decisions

| Decision | Why it matters |
| --- | --- |
| Local-only chat history | `ChatRepositoryImpl` stores chat sessions in Hive on-device; the backend does not receive full conversation history |
| Maximum of 3 selected papers | Enforced in Flutter and validated again by backend request models to keep the UX and prompt context bounded |
| Background PDF processing | `BackgroundTasks` prevents PDF download/extraction/embedding work from blocking the request-response cycle |
| Two Dio instances | One client is dedicated to backend JSON APIs, and one to arXiv XML plus rate limiting/retries |
| `Either<Failure, T>` repository contracts | Forces explicit success/failure handling in use cases and Cubits instead of leaking exceptions into the UI |
| FAISS persisted on startup/shutdown | The backend loads the index on app startup and saves it on shutdown so embeddings survive restarts |
| arXiv rate limiting in the client | The app respects arXiv’s request pacing with a dedicated interceptor and exponential backoff on `503` |

## Testing

### Flutter

Run from the project root:

```bash
flutter test
```

Current Flutter tests live in `test/` and include the default widget test scaffold.

### Backend

Run from `backend/`:

```bash
cd backend
source .venv/bin/activate
pytest
```

Backend tests cover:

- API endpoints
- PDF processing
- Chunking
- Vector-store behavior
- RAG service behavior

## Useful Source Anchors

| Area | File |
| --- | --- |
| Flutter entry point | `lib/main.dart` |
| Flutter DI | `lib/core/di/injection_container.dart` |
| Backend entry point | `backend/main.py` |
| Backend dependency wiring | `backend/app/api/dependencies.py` |
| RAG orchestration | `backend/app/services/rag_service.py` |
| FAISS vector store | `backend/app/services/vector_store.py` |
| Summary service | `backend/app/services/summarizer.py` |
| Slash command validation | `lib/domain/usecases/process_slash_command.dart` |

