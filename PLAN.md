╭─────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Implementation Plan: AI Research Paper Search, Summarization & Chat App                                 │
│                                                                                                         │
│ Context                                                                                                 │
│                                                                                                         │
│ This is a greenfield college project. Only a TRD.md specification exists — no code yet. The goal is to  │
│ implement the complete application: a Flutter mobile app (frontend) that talks to a FastAPI Python      │
│ backend, which runs a RAG pipeline over academic papers from arXiv. The project root                    │
│ (/Users/lkrjangid/Desktop/college_project) will be the Flutter project, with backend/ as a subdirectory │
│  for the Python server.                                                                                 │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 1: Backend — Scaffolding & Configuration                                                          │
│                                                                                                         │
│ Goal: Create directory structure, dependencies, and config layer.                                       │
│                                                                                                         │
│ Files to create:                                                                                        │
│                                                                                                         │
│ 1. backend/requirements.txt                                                                             │
│ fastapi==0.110.3                                                                                        │
│ uvicorn[standard]==0.27.1                                                                               │
│ pydantic==2.7.1                                                                                         │
│ pydantic-settings==2.2.1                                                                                │
│ python-dotenv==1.0.1                                                                                    │
│ PyMuPDF==1.24.3                                                                                         │
│ faiss-cpu==1.7.4                                                                                        │
│ numpy==1.26.4                                                                                           │
│ httpx==0.27.0                                                                                           │
│ google-cloud-aiplatform==1.49.0                                                                         │
│ slowapi==0.1.9                                                                                          │
│ python-multipart==0.0.9                                                                                 │
│ pytest==8.1.1                                                                                           │
│ pytest-asyncio==0.23.6                                                                                  │
│ pytest-cov==5.0.0                                                                                       │
│ 2. backend/.env.example — VERTEX_PROJECT_ID, VERTEX_LOCATION=us-central1,                               │
│ GOOGLE_APPLICATION_CREDENTIALS, GEMINI_MODEL=gemini-1.5-pro, EMBEDDING_MODEL=text-embedding-004,        │
│ FAISS_INDEX_PATH=./data/faiss_index, DEBUG=true, CORS_ORIGINS=*                                         │
│ 3. backend/app/__init__.py (empty)                                                                      │
│ 4. backend/app/config.py — pydantic_settings.BaseSettings with all env vars, get_settings() with        │
│ lru_cache                                                                                               │
│ 5. backend/app/core/__init__.py, backend/app/core/exceptions.py — PDFProcessingError, EmbeddingError,   │
│ VectorStoreError, RAGError, PaperNotFoundError + exception-to-HTTPException mapper                      │
│ 6. backend/app/core/middleware.py — CORS via CORSMiddleware, rate limiting via slowapi (100 req/min)    │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 2: Backend — Pydantic Models                                                                      │
│                                                                                                         │
│ Goal: Define all request/response models and internal data structures.                                  │
│                                                                                                         │
│ Files:                                                                                                  │
│                                                                                                         │
│ 1. backend/app/models/__init__.py (empty)                                                               │
│ 2. backend/app/models/paper.py — PaperMetadata, ProcessingStatus enum, PaperStatus                      │
│ 3. backend/app/models/chunk.py — dataclasses: ExtractedPage, ProcessedDocument, Chunk, SearchResult     │
│ 4. backend/app/models/chat.py — Citation, RAGResponse                                                   │
│ 5. backend/app/models/requests.py — all Pydantic request/response schemas:                              │
│   - ProcessPaperRequest (paper_id, title, authors, pdf_url — backend downloads the PDF)                 │
│   - ChatQueryRequest (question, paper_ids[1-3], paper_titles, session_id?)                              │
│   - SlashCommandRequest, SummaryRequest                                                                 │
│   - Corresponding response models                                                                       │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 3: Backend — Leaf Services                                                                        │
│                                                                                                         │
│ Goal: Implement services with no internal dependencies (building blocks).                               │
│                                                                                                         │
│ Files:                                                                                                  │
│                                                                                                         │
│ 1. backend/app/services/__init__.py (empty)                                                             │
│ 2. backend/app/services/pdf_processor.py — PDFProcessor: PyMuPDF text extraction with page mapping,     │
│ _clean_text for artifacts. Wrap sync fitz calls in asyncio.to_thread.                                   │
│ 3. backend/app/services/chunker.py — SemanticChunker: 512-token chunks, 50-token overlap,               │
│ paragraph-aware, page number preserved, discard <100 char fragments.                                    │
│ 4. backend/app/services/vertex_ai_client.py — VertexAIClient: Gemini 1.5 Pro wrapper, generate() with   │
│ temp=0.3, max_tokens=2048, top_p=0.95.                                                                  │
│ 5. backend/app/services/embedding_service.py — EmbeddingService: text-embedding-004, 768-dim, batch     │
│ 250, embed_texts() and embed_query(). Wrap in asyncio.to_thread.                                        │
│ 6. backend/app/services/vector_store.py — VectorStore: FAISS IndexFlatIP, L2 normalize,                 │
│ add_embeddings(), search() with paper_id filter + score threshold 0.3 + 10x expansion, remove_paper()   │
│ by rebuild, save()/load() for persistence.                                                              │
│ 7. backend/app/utils/__init__.py, backend/app/utils/citation_formatter.py                               │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 4: Backend — Composite Services                                                                   │
│                                                                                                         │
│ Goal: Higher-level services that orchestrate leaf services.                                             │
│                                                                                                         │
│ Files:                                                                                                  │
│                                                                                                         │
│ 1. backend/app/services/rag_service.py — RAGService: embed query → FAISS search → build context →       │
│ Gemini generate → extract citations. Also execute_command() for slash commands (/compare, /gaps,        │
│ /review, /code, /visualize, /search, /explain) with specialized prompts.                                │
│ 2. backend/app/services/summarizer.py — SummarizerService: 3 expertise-level prompt templates           │
│ (beginner/intermediate/expert), summarize() truncates to 8000 chars.                                    │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 5: Backend — API Layer & Entry Point                                                              │
│                                                                                                         │
│ Goal: Wire DI, expose HTTP endpoints, create app entry point.                                           │
│                                                                                                         │
│ Files:                                                                                                  │
│                                                                                                         │
│ 1. backend/app/api/__init__.py, backend/app/api/routes/__init__.py (empty)                              │
│ 2. backend/app/api/dependencies.py — DI container using lru_cache singletons for all services.          │
│ In-memory paper_status_store dict.                                                                      │
│ 3. backend/app/api/routes/health.py — GET /health, GET /health/ready                                    │
│ 4. backend/app/api/routes/papers.py — POST /api/papers/process (accepts JSON with pdf_url, runs         │
│ processing as BackgroundTask: download → extract → chunk → embed → index), GET                          │
│ /api/papers/{paper_id}/status, DELETE /api/papers/{paper_id}                                            │
│ 5. backend/app/api/routes/chat.py — POST /api/chat/query (RAG), POST /api/chat/command (slash commands) │
│ 6. backend/app/api/routes/summary.py — POST /api/summary/generate                                       │
│ 7. backend/main.py — FastAPI app with lifespan (load/save FAISS on startup/shutdown), middleware,       │
│ routes                                                                                                  │
│ 8. backend/Dockerfile — python:3.10-slim, install deps, expose 8000                                     │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 6: Backend — Tests                                                                                │
│                                                                                                         │
│ Files:                                                                                                  │
│                                                                                                         │
│ 1. backend/tests/__init__.py, backend/tests/conftest.py — fixtures with mocked Vertex AI, sample PDFs   │
│ via PyMuPDF                                                                                             │
│ 2. backend/tests/test_pdf_processor.py — valid PDF, hyphenation cleanup, short page skip                │
│ 3. backend/tests/test_chunker.py — chunk count, overlap presence, page mapping, small fragment discard  │
│ 4. backend/tests/test_vector_store.py — add/search, paper_id filtering, score threshold, save/load,     │
│ remove                                                                                                  │
│ 5. backend/tests/test_rag_service.py — query with citations, no results fallback, slash commands        │
│ 6. backend/tests/test_api_endpoints.py — integration tests with dependency overrides                    │
│ 7. backend/scripts/seed_test_data.py — smoke test script                                                │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 7: Flutter — Project Scaffold & Dependencies                                                      │
│                                                                                                         │
│ Goal: Create Flutter project at repo root, configure pubspec.yaml.                                      │
│                                                                                                         │
│ Run flutter create --org com.researchpaper --project-name research_assistant . from project root.       │
│                                                                                                         │
│ pubspec.yaml dependencies:                                                                              │
│                                                                                                         │
│ dependencies:                                                                                           │
│   flutter_bloc: ^8.1.6                                                                                  │
│   equatable: ^2.0.7                                                                                     │
│   get_it: ^7.7.0                                                                                        │
│   dio: ^5.7.0                                                                                           │
│   xml: ^6.5.0                                                                                           │
│   hive: ^2.2.3                                                                                          │
│   hive_flutter: ^1.1.0                                                                                  │
│   dartz: ^0.10.1                                                                                        │
│   intl: ^0.19.0                                                                                         │
│   uuid: ^4.5.1                                                                                          │
│   url_launcher: ^6.3.1                                                                                  │
│   google_fonts: ^6.2.1                                                                                  │
│   shimmer: ^3.0.0                                                                                       │
│                                                                                                         │
│ dev_dependencies:                                                                                       │
│   build_runner: ^2.4.13                                                                                 │
│   hive_generator: ^2.0.1                                                                                │
│   mockito: ^5.4.4                                                                                       │
│   bloc_test: ^9.1.7                                                                                     │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 8: Flutter — Core Infrastructure                                                                  │
│                                                                                                         │
│ Goal: Constants, theme, network, utilities, DI shell.                                                   │
│                                                                                                         │
│ Files:                                                                                                  │
│                                                                                                         │
│ 1. lib/core/constants/api_constants.dart — arXiv base URL, backend base URL (configurable), endpoint    │
│ paths                                                                                                   │
│ 2. lib/core/constants/app_constants.dart — maxPapersPerSession=3, searchPageSize=10, arxivRateLimit=3s, │
│  maxChatMessages=50                                                                                     │
│ 3. lib/core/constants/hive_keys.dart — box name constants                                               │
│ 4. lib/core/theme/colors.dart — AppColors (primary=#1E88E5, secondary=#F9A825, citation colors)         │
│ 5. lib/core/theme/app_theme.dart — Material 3 light/dark themes                                         │
│ 6. lib/core/network/api_exceptions.dart — ServerException, NetworkException, Failure sealed types for   │
│ Either                                                                                                  │
│ 7. lib/core/network/api_client.dart — Two Dio instances: backendDio and arxivDio                        │
│ 8. lib/core/network/interceptors/rate_limit_interceptor.dart — 1-req-per-3s for arXiv, exponential      │
│ backoff on 503                                                                                          │
│ 9. lib/core/utils/xml_parser.dart — ArxivXmlParser.parseSearchResponse(xmlString) → List<Paper>         │
│ 10. lib/core/utils/date_formatter.dart — format dates, time-ago                                         │
│ 11. lib/core/di/injection_container.dart — GetIt shell, registers Dio instances (extended in later      │
│ phases)                                                                                                 │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 9: Flutter — Domain Layer                                                                         │
│                                                                                                         │
│ Goal: Pure business logic — entities, abstract repos, use cases.                                        │
│                                                                                                         │
│ Files:                                                                                                  │
│                                                                                                         │
│ 1. lib/domain/entities/paper.dart — Paper extends Equatable (arxivId, title, authors, abstract, pdfUrl, │
│  publishedDate, categories)                                                                             │
│ 2. lib/domain/entities/message.dart — Message (role, content, citations?, timestamp, slashCommand?) +   │
│ Citation (paperTitle, pageNumber, chunkText)                                                            │
│ 3. lib/domain/entities/chat_session.dart — ChatSession (sessionId, paperIds, messages, createdAt,       │
│ updatedAt)                                                                                              │
│ 4. lib/domain/repositories/paper_repository.dart — abstract: searchPapers(), processPaper(),            │
│ getPaperStatus(), getSummary() — all return Either<Failure, T>                                          │
│ 5. lib/domain/repositories/chat_repository.dart — abstract: sendChatQuery(), executeSlashCommand(),     │
│ getSession(), getAllSessions(), saveSession(), deleteSession()                                          │
│ 6. lib/domain/usecases/search_papers.dart, get_paper_summary.dart, send_chat_message.dart,              │
│ process_slash_command.dart                                                                              │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 10: Flutter — Data Layer                                                                          │
│                                                                                                         │
│ Goal: Hive models, data sources, repository implementations.                                            │
│                                                                                                         │
│ Files:                                                                                                  │
│                                                                                                         │
│ 1. lib/data/models/paper_model.dart — @HiveType(typeId: 0), 7 fields, toEntity()/fromEntity()           │
│ 2. lib/data/models/chat_session_model.dart — @HiveType(typeId: 1)                                       │
│ 3. lib/data/models/message_model.dart — @HiveType(typeId: 2)                                            │
│ 4. lib/data/models/citation_model.dart — @HiveType(typeId: 3)                                           │
│ 5. Run dart run build_runner build --delete-conflicting-outputs to generate .g.dart files               │
│ 6. lib/data/datasources/remote/arxiv_api_service.dart — uses arxivDio, returns raw XML                  │
│ 7. lib/data/datasources/remote/backend_api_service.dart — uses backendDio, all backend endpoints        │
│ 8. lib/data/datasources/local/chat_local_datasource.dart — Hive CRUD for chat sessions                  │
│ 9. lib/data/datasources/local/settings_local_datasource.dart — Hive for expertise level, dark mode      │
│ 10. lib/data/repositories/paper_repository_impl.dart — bridges arXiv XML + backend JSON                 │
│ 11. lib/data/repositories/chat_repository_impl.dart — bridges backend + Hive                            │
│ 12. Update DI container — register all datasources, repos, use cases                                    │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 11: Flutter — Cubits (State Management)                                                           │
│                                                                                                         │
│ Goal: All 5 cubits with states.                                                                         │
│                                                                                                         │
│ Files:                                                                                                  │
│                                                                                                         │
│ 1. lib/presentation/cubits/search/search_state.dart + search_cubit.dart —                               │
│ SearchInitial/Loading/Loaded/Error, search(), loadMore()                                                │
│ 2. lib/presentation/cubits/paper_selection/paper_selection_state.dart + paper_selection_cubit.dart —    │
│ max 3, addPaper(), removePaper(), clearAll()                                                            │
│ 3. lib/presentation/cubits/paper_details/paper_details_state.dart + paper_details_cubit.dart —          │
│ loadPaper(), generateSummary()                                                                          │
│ 4. lib/presentation/cubits/chat/chat_state.dart + chat_cubit.dart — sendMessage() (optimistic UI),      │
│ _handleSlashCommand(), _persistSession() to Hive                                                        │
│ 5. lib/presentation/cubits/settings/settings_state.dart + settings_cubit.dart — loadSettings(),         │
│ setExpertiseLevel(), toggleDarkMode(), clearAllData()                                                   │
│ 6. Update DI container — register all cubits                                                            │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 12: Flutter — App Shell                                                                           │
│                                                                                                         │
│ Goal: Entry point, routing, BlocProviders.                                                              │
│                                                                                                         │
│ Files:                                                                                                  │
│                                                                                                         │
│ 1. lib/app/routes.dart — named routes: / (search), /paper-details, /chat, /settings; onGenerateRoute    │
│ 2. lib/app/app.dart — MultiBlocProvider with global cubits (PaperSelectionCubit, SettingsCubit),        │
│ MaterialApp with theme from SettingsCubit                                                               │
│ 3. lib/main.dart — WidgetsFlutterBinding, Hive init, register 4 TypeAdapters, open 3 boxes,             │
│ initDependencies(), runApp()                                                                            │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 13: Flutter — UI Pages & Widgets                                                                  │
│                                                                                                         │
│ Goal: All screens. Order: shared widgets → Search → Paper Details → Chat → Settings.                    │
│                                                                                                         │
│ Shared Widgets:                                                                                         │
│                                                                                                         │
│ 1. lib/presentation/widgets/loading_overlay.dart — semi-transparent overlay with spinner                │
│ 2. lib/presentation/widgets/paper_selection_bar.dart — bottom bar with selected paper chips + "Chat"    │
│ button                                                                                                  │
│                                                                                                         │
│ Search Screen:                                                                                          │
│                                                                                                         │
│ 3. lib/presentation/pages/search/widgets/search_bar_widget.dart — M3 SearchBar with debounce            │
│ 4. lib/presentation/pages/search/widgets/paper_card_widget.dart — card with title, authors, date,       │
│ categories, abstract preview, "Add to Chat" button                                                      │
│ 5. lib/presentation/pages/search/search_page.dart — page-scoped SearchCubit, ListView with pagination,  │
│ shimmer loading, PaperSelectionBar                                                                      │
│                                                                                                         │
│ Paper Details Screen:                                                                                   │
│                                                                                                         │
│ 6. lib/presentation/pages/paper_details/widgets/metadata_section.dart — full metadata display           │
│ 7. lib/presentation/pages/paper_details/widgets/summary_card.dart — generate/display summary with level │
│  selector                                                                                               │
│ 8. lib/presentation/pages/paper_details/paper_details_page.dart — CustomScrollView, FAB "Add to Chat"   │
│                                                                                                         │
│ Chat Screen:                                                                                            │
│                                                                                                         │
│ 9. lib/presentation/pages/chat/widgets/citation_chip.dart — styled [Paper, Page N] chip                 │
│ 10. lib/presentation/pages/chat/widgets/message_bubble.dart — user/assistant bubbles with citations     │
│ 11. lib/presentation/pages/chat/widgets/slash_command_overlay.dart — autocomplete overlay when typing / │
│ 12. lib/presentation/pages/chat/chat_page.dart — page-scoped ChatCubit, message list, typing indicator, │
│  input with slash detection                                                                             │
│                                                                                                         │
│ Settings Screen:                                                                                        │
│                                                                                                         │
│ 13. lib/presentation/pages/settings/settings_page.dart — expertise level, dark mode toggle, clear data  │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 14: Flutter — Polish & Error Handling                                                             │
│                                                                                                         │
│ 1. Offline resilience — cache search results in Hive, load from cache on network failure                │
│ 2. Empty states — illustrations for no results, starter prompts in chat                                 │
│ 3. Loading states — shimmer for search cards and summary                                                │
│ 4. Error recovery — retry buttons on all error states, specific messaging for rate limits vs server     │
│ errors                                                                                                  │
│                                                                                                         │
│ ---                                                                                                     │
│ Phase 15: Flutter — Tests                                                                               │
│                                                                                                         │
│ 1. test/core/utils/xml_parser_test.dart — arXiv XML parsing                                             │
│ 2. test/cubits/search_cubit_test.dart — search/loadMore flows                                           │
│ 3. test/cubits/paper_selection_cubit_test.dart — add/remove/max limit                                   │
│ 4. test/cubits/chat_cubit_test.dart — message send, slash commands                                      │
│ 5. test/data/repositories/paper_repository_impl_test.dart — XML parsing delegation, error mapping       │
│                                                                                                         │
│ ---                                                                                                     │
│ Key Design Decisions                                                                                    │
│                                                                                                         │
│ ┌─────────────────────────────────────┬──────────────────────────────────────────────────────────────── │
│ ───┐                                                                                                    │
│ │              Decision               │                             Rationale                           │
│    │                                                                                                    │
│ ├─────────────────────────────────────┼──────────────────────────────────────────────────────────────── │
│ ───┤                                                                                                    │
│ │ Backend downloads PDF by URL (not   │ Avoids mobile uploading 50MB blobs; backend fetches from arXiv  │
│    │                                                                                                    │
│ │ file upload)                        │ directly                                                        │
│    │                                                                                                    │
│ ├─────────────────────────────────────┼──────────────────────────────────────────────────────────────── │
│ ───┤                                                                                                    │
│ │ BackgroundTasks for PDF processing  │ 30-45s processing; endpoint returns immediately, client polls   │
│    │                                                                                                    │
│ │                                     │ /status                                                         │
│    │                                                                                                    │
│ ├─────────────────────────────────────┼──────────────────────────────────────────────────────────────── │
│ ───┤                                                                                                    │
│ │ In-memory paper status store        │ Acceptable for college project scope; production would use      │
│ Redis  │                                                                                                │
│ ├─────────────────────────────────────┼──────────────────────────────────────────────────────────────── │
│ ───┤                                                                                                    │
│ │ FAISS remove_paper by full rebuild  │ IndexFlatIP has no delete; rebuild is O(n) but fast at expected │
│    │                                                                                                    │
│ │                                     │ scale                                                           │
│    │                                                                                                    │
│ ├─────────────────────────────────────┼──────────────────────────────────────────────────────────────── │
│ ───┤                                                                                                    │
│ │ Two Dio instances (arXiv + backend) │ arXiv rate limiter must not affect backend calls                │
│    │                                                                                                    │
│ ├─────────────────────────────────────┼──────────────────────────────────────────────────────────────── │
│ ───┤                                                                                                    │
│ │ Global vs page-scoped cubits        │ PaperSelectionCubit/SettingsCubit global; others page-scoped to │
│    │                                                                                                    │
│ │                                     │ avoid stale state                                               │
│    │                                                                                                    │
│ ├─────────────────────────────────────┼──────────────────────────────────────────────────────────────── │
│ ───┤                                                                                                    │
│ │ Either<Failure, T> for all repo     │ Forces explicit error handling, no unhandled exceptions leak to │
│    │                                                                                                    │
│ │ methods                             │ UI                                                              │
│    │                                                                                                    │
│ ├─────────────────────────────────────┼──────────────────────────────────────────────────────────────── │
│ ───┤                                                                                                    │
│ │ Chat history local-only (Hive)      │ Privacy requirement from TRD; never sent to backend             │
│    │                                                                                                    │
│ └─────────────────────────────────────┴──────────────────────────────────────────────────────────────── │
│ ───┘                                                                                                    │
│                                                                                                         │
│ ---                                                                                                     │
│ Verification                                                                                            │
│                                                                                                         │
│ After each backend phase:                                                                               │
│ cd backend && pip install -r requirements.txt && python -c "from app.config import get_settings"        │
│ pytest tests/ -v                                                                                        │
│ uvicorn main:app --reload  # smoke test endpoints                                                       │
│                                                                                                         │
│ After each Flutter phase:                                                                               │
│ flutter analyze                                                                                         │
│ flutter test                                                                                            │
│ flutter run  # visual verification                                                                      │
│                                                                                                         │
│ End-to-end test:                                                                                        │
│ 1. Start backend: cd backend && uvicorn main:app --reload --port 8000                                   │
│ 2. Run Flutter app: flutter run                                                                         │
│ 3. Search for "attention mechanism" → verify arXiv results appear                                       │
│ 4. Tap a paper → verify details page with metadata                                                      │
│ 5. Add 1-3 papers → verify selection bar appears                                                        │
│ 6. Open chat → ask a question → verify RAG response with citations                                      │
│ 7. Try /summary command → verify adaptive summary                                                       │
│ 8. Toggle dark mode in settings → verify theme change                                                   │
│ 9. Kill network → verify cached search results and local chat history still accessible                  │
╰─────────────────────────────────────────────────────────────────────────────────────────────────────────╯

