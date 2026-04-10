# Technical Requirements Document (TRD)

## AI-Based Research Paper Search, Summarization and Chat Application

**Version:** 1.1  
**Last Updated:** April 2026  
**Document Status:** Implementation Ready  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [System Overview](#2-system-overview)
3. [Architecture Design](#3-architecture-design)
4. [Frontend Technical Specifications](#4-frontend-technical-specifications)
5. [Backend Technical Specifications](#5-backend-technical-specifications)
6. [AI/ML Pipeline](#6-aiml-pipeline)
7. [Data Models](#7-data-models)
8. [API Specifications](#8-api-specifications)
9. [External Integrations](#9-external-integrations)
10. [Security Requirements](#10-security-requirements)
11. [Performance Requirements](#11-performance-requirements)
12. [Infrastructure & Deployment](#12-infrastructure--deployment)
13. [Testing Strategy](#13-testing-strategy)
14. [Appendices](#14-appendices)
15. [Implementation Roadmap](#15-implementation-roadmap)

---

## 1. Executive Summary

### 1.1 Purpose

This Technical Requirements Document defines the complete technical specifications for building an AI-powered mobile application that enables researchers to search, summarize, and interactively chat with academic research papers. The system leverages Retrieval Augmented Generation (RAG) to provide citation-aware, context-grounded responses.

### 1.2 Scope

The document covers:
- Three-tier architecture (Flutter mobile, FastAPI backend, Vector database)
- RAG pipeline implementation with Google Vertex AI
- arXiv API integration for paper discovery
- Multi-paper chat functionality (up to 3 papers simultaneously)
- Adaptive summarization based on expertise levels
- Local-first privacy architecture
- Concrete backend and Flutter implementation phases, file ownership, dependencies, and verification commands

### 1.3 Target Audience

- Mobile developers (Flutter/Dart)
- Backend engineers (Python/FastAPI)
- ML engineers (RAG, embeddings)
- DevOps engineers
- QA engineers

---

## 2. System Overview

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                            │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Flutter Mobile Application                    │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │   │
│  │  │  Search  │ │  Paper   │ │   Chat   │ │    Settings      │   │   │
│  │  │  Module  │ │ Details  │ │  Module  │ │    Module        │   │   │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────────┬─────────┘   │   │
│  │       │            │            │                │             │   │
│  │  ┌────┴────────────┴────────────┴────────────────┴─────────┐   │   │
│  │  │              Bloc/Cubit State Management                 │   │   │
│  │  └──────────────────────────┬───────────────────────────────┘   │   │
│  │                             │                                   │   │
│  │  ┌──────────────────────────┴───────────────────────────────┐   │   │
│  │  │                  Hive Local Storage                       │   │   │
│  │  └──────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTPS/REST
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          APPLICATION LAYER                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     FastAPI Backend Server                       │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐   │   │
│  │  │    PDF      │ │  Embedding  │ │       RAG Pipeline       │   │   │
│  │  │  Processor  │ │   Engine    │ │   (Query → Response)     │   │   │
│  │  └──────┬──────┘ └──────┬──────┘ └───────────┬─────────────┘   │   │
│  │         │               │                     │                 │   │
│  │  ┌──────┴───────────────┴─────────────────────┴─────────────┐   │   │
│  │  │                    Service Layer                          │   │   │
│  │  └──────────────────────────┬────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
┌──────────────────────┐ ┌──────────────────┐ ┌───────────────────────┐
│      DATA LAYER      │ │  EXTERNAL APIS   │ │    AI SERVICES        │
│  ┌────────────────┐  │ │ ┌──────────────┐ │ │ ┌─────────────────┐   │
│  │  FAISS Vector  │  │ │ │   arXiv API  │ │ │ │  Vertex AI      │   │
│  │     Index      │  │ │ │ (Atom/XML)   │ │ │ │  Gemini 1.5 Pro │   │
│  └────────────────┘  │ │ └──────────────┘ │ │ └─────────────────┘   │
│  ┌────────────────┐  │ │                  │ │ ┌─────────────────┐   │
│  │ Session Cache  │  │ │                  │ │ │  Embeddings API │   │
│  │  (In-Memory)   │  │ │                  │ │ │ text-embed-004  │   │
│  └────────────────┘  │ │                  │ │ └─────────────────┘   │
└──────────────────────┘ └──────────────────┘ └───────────────────────┘
```

### 2.2 Core Components

| Component | Technology | Responsibility |
|-----------|------------|----------------|
| Mobile App | Flutter 3.x (Dart) | UI, local storage, API consumption |
| State Management | Bloc/Cubit + GetIt DI | Reactive state, dependency injection |
| Backend Server | FastAPI (Python 3.10+) | PDF processing, RAG orchestration |
| Vector Store | FAISS | Semantic similarity search |
| AI Platform | Google Vertex AI | LLM inference, embeddings |
| Local Storage | Hive | Chat sessions, user preferences |

---

## 3. Architecture Design

### 3.1 Design Principles

1. **Local-First Privacy**: Chat histories and conversation data stored exclusively on-device
2. **Separation of Concerns**: Clear boundaries between presentation, business logic, and data layers
3. **Offline Resilience**: Cached search results and local chat history accessible without network
4. **Horizontal Scalability**: Stateless backend design for easy scaling
5. **Citation Grounding**: All AI responses must include verifiable source citations

### 3.2 Component Interaction Flow

#### 3.2.1 Paper Search Flow

```
┌──────┐     ┌─────────────┐     ┌─────────────┐     ┌──────────┐
│ User │────▶│ SearchCubit │────▶│ arXiv API   │────▶│ XML Parse│
└──────┘     └─────────────┘     └─────────────┘     └────┬─────┘
                                                          │
    ┌─────────────────────────────────────────────────────┘
    ▼
┌──────────────┐     ┌──────────────────┐     ┌────────────────┐
│ Paper Models │────▶│ UI ListView      │────▶│ Display Results│
└──────────────┘     └──────────────────┘     └────────────────┘
```

#### 3.2.2 RAG Chat Flow

```
┌──────┐     ┌───────────┐     ┌─────────────────┐     ┌───────────────┐
│ User │────▶│ ChatCubit │────▶│ Backend /chat   │────▶│ Query Embed   │
│Query │     └───────────┘     └─────────────────┘     └───────┬───────┘
└──────┘                                                       │
                                                               ▼
┌───────────────┐     ┌─────────────────┐     ┌────────────────────────┐
│ UI Response   │◀────│ Citation Append │◀────│ FAISS Similarity Search│
│ + Citations   │     │ [Paper, Page]   │     │ (top-k chunks)         │
└───────────────┘     └─────────────────┘     └────────────┬───────────┘
                              ▲                            │
                              │                            ▼
                      ┌───────┴───────────────────────────────────────┐
                      │         Vertex AI Gemini 1.5 Pro              │
                      │  (System Prompt + Context Chunks + Question)  │
                      └───────────────────────────────────────────────┘
```

### 3.3 Data Flow Diagram (DFD Level 1)

**Processes:**
- **P1.0 - Search Processing**: Handles arXiv API queries and response parsing
- **P2.0 - Document Processing**: PDF extraction, text chunking with page mapping
- **P3.0 - Embedding Generation**: Vector representation using Vertex AI
- **P4.0 - Chat Processing**: RAG-based question answering with citations
- **P5.0 - Summary Generation**: Adaptive summarization per expertise level

**Data Stores:**
- **D1 - Local Chat Store**: Hive database on device
- **D2 - Vector Index**: FAISS index on backend
- **D3 - Session Cache**: In-memory embedding cache

---

## 4. Frontend Technical Specifications

### 4.1 Technology Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Framework | Flutter | 3.19+ |
| Language | Dart | 3.3+ |
| State Management | flutter_bloc | 8.x |
| Dependency Injection | get_it | 7.x |
| Local Database | Hive | 2.x |
| HTTP Client | dio | 5.x |
| XML Parsing | xml | 6.x |
| UI Components | Material 3 | Built-in |

### 4.1.1 Flutter Dependencies

The Flutter project is created at the repository root with:

```bash
flutter create --org com.researchpaper --project-name research_assistant .
```

`pubspec.yaml` must include:

```yaml
dependencies:
  flutter_bloc: ^8.1.6
  equatable: ^2.0.7
  get_it: ^7.7.0
  dio: ^5.7.0
  xml: ^6.5.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  dartz: ^0.10.1
  intl: ^0.19.0
  uuid: ^4.5.1
  url_launcher: ^6.3.1
  google_fonts: ^6.2.1
  shimmer: ^3.0.0

dev_dependencies:
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
  mockito: ^5.4.4
  bloc_test: ^9.1.7
```

### 4.2 Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── routes.dart
├── core/
│   ├── constants/
│   │   ├── api_constants.dart
│   │   ├── app_constants.dart
│   │   └── hive_keys.dart
│   ├── di/
│   │   └── injection_container.dart      # GetIt setup
│   ├── network/
│   │   ├── api_client.dart               # Dio configuration
│   │   ├── api_exceptions.dart
│   │   └── interceptors/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── colors.dart
│   └── utils/
│       ├── xml_parser.dart               # arXiv Atom parser
│       └── date_formatter.dart
├── data/
│   ├── models/
│   │   ├── paper_model.dart
│   │   ├── paper_model.g.dart            # Hive TypeAdapter
│   │   ├── chat_session_model.dart
│   │   ├── message_model.dart
│   │   └── chunk_model.dart
│   ├── repositories/
│   │   ├── paper_repository.dart
│   │   ├── paper_repository_impl.dart
│   │   ├── chat_repository.dart
│   │   └── chat_repository_impl.dart
│   └── datasources/
│       ├── remote/
│       │   ├── arxiv_api_service.dart
│       │   └── backend_api_service.dart
│       └── local/
│           ├── chat_local_datasource.dart
│           └── settings_local_datasource.dart
├── domain/
│   ├── entities/
│   │   ├── paper.dart
│   │   ├── chat_session.dart
│   │   └── message.dart
│   ├── repositories/
│   │   ├── paper_repository.dart         # Abstract
│   │   └── chat_repository.dart          # Abstract
│   └── usecases/
│       ├── search_papers.dart
│       ├── get_paper_summary.dart
│       ├── send_chat_message.dart
│       └── process_slash_command.dart
└── presentation/
    ├── cubits/
    │   ├── search/
    │   │   ├── search_cubit.dart
    │   │   └── search_state.dart
    │   ├── paper_details/
    │   │   ├── paper_details_cubit.dart
    │   │   └── paper_details_state.dart
    │   ├── chat/
    │   │   ├── chat_cubit.dart
    │   │   └── chat_state.dart
    │   ├── paper_selection/
    │   │   ├── paper_selection_cubit.dart
    │   │   └── paper_selection_state.dart
    │   └── settings/
    │       ├── settings_cubit.dart
    │       └── settings_state.dart
    ├── pages/
    │   ├── search/
    │   │   ├── search_page.dart
    │   │   └── widgets/
    │   │       ├── search_bar_widget.dart
    │   │       └── paper_card_widget.dart
    │   ├── paper_details/
    │   │   ├── paper_details_page.dart
    │   │   └── widgets/
    │   │       ├── metadata_section.dart
    │   │       └── summary_card.dart
    │   ├── chat/
    │   │   ├── chat_page.dart
    │   │   └── widgets/
    │   │       ├── message_bubble.dart
    │   │       ├── citation_chip.dart
    │   │       └── slash_command_overlay.dart
    │   └── settings/
    │       └── settings_page.dart
    └── widgets/
        ├── paper_selection_bar.dart      # Bottom bar showing selected papers
        └── loading_overlay.dart
```

### 4.3 Cubit Specifications

#### 4.3.1 SearchCubit

```dart
// States
abstract class SearchState {}
class SearchInitial extends SearchState {}
class SearchLoading extends SearchState {}
class SearchLoaded extends SearchState {
  final List<Paper> papers;
  final int currentPage;
  final bool hasMore;
}
class SearchError extends SearchState {
  final String message;
}

// Cubit
class SearchCubit extends Cubit<SearchState> {
  final SearchPapersUseCase _searchPapers;
  
  String _lastQuery = '';
  int _currentPage = 0;
  final int _pageSize = 10;
  
  Future<void> search(String query) async {
    emit(SearchLoading());
    _lastQuery = query;
    _currentPage = 0;
    final result = await _searchPapers(
      query: query,
      start: 0,
      maxResults: _pageSize,
    );
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (papers) => emit(SearchLoaded(
        papers: papers,
        currentPage: 0,
        hasMore: papers.length == _pageSize,
      )),
    );
  }
  
  Future<void> loadMore() async {
    // Pagination implementation
  }
}
```

#### 4.3.2 ChatCubit

```dart
// States
abstract class ChatState {}
class ChatInitial extends ChatState {}
class ChatSessionLoaded extends ChatState {
  final ChatSession session;
  final List<Message> messages;
  final bool isProcessing;
}
class ChatError extends ChatState {
  final String message;
}

// Cubit
class ChatCubit extends Cubit<ChatState> {
  final SendChatMessageUseCase _sendMessage;
  final ProcessSlashCommandUseCase _processCommand;
  final ChatRepository _chatRepository;
  
  List<Paper> _selectedPapers = [];  // Max 3
  
  Future<void> sendMessage(String content) async {
    if (content.startsWith('/')) {
      await _handleSlashCommand(content);
      return;
    }
    
    // Add user message to UI immediately
    _addMessage(Message(role: 'user', content: content));
    
    // Set processing state
    emit(ChatSessionLoaded(
      session: _currentSession,
      messages: _messages,
      isProcessing: true,
    ));
    
    // Call backend RAG API
    final result = await _sendMessage(
      question: content,
      paperIds: _selectedPapers.map((p) => p.arxivId).toList(),
    );
    
    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (response) {
        _addMessage(Message(
          role: 'assistant',
          content: response.text,
          citations: response.citations,
        ));
        _persistSession();
      },
    );
  }
  
  Future<void> _handleSlashCommand(String command) async {
    // Parse: /summary, /compare, /review, /gaps, /code, /visualize, /search, /explain
  }
}
```

#### 4.3.3 PaperSelectionCubit

```dart
class PaperSelectionCubit extends Cubit<PaperSelectionState> {
  static const int maxPapers = 3;
  
  void addPaper(Paper paper) {
    if (state.selectedPapers.length >= maxPapers) {
      emit(state.copyWith(error: 'Maximum 3 papers allowed'));
      return;
    }
    if (state.selectedPapers.any((p) => p.arxivId == paper.arxivId)) {
      return; // Already selected
    }
    emit(state.copyWith(
      selectedPapers: [...state.selectedPapers, paper],
    ));
  }
  
  void removePaper(String arxivId) {
    emit(state.copyWith(
      selectedPapers: state.selectedPapers
          .where((p) => p.arxivId != arxivId)
          .toList(),
    ));
  }
  
  void clearAll() {
    emit(PaperSelectionState.initial());
  }
}
```

### 4.4 Hive Data Models

```dart
@HiveType(typeId: 0)
class PaperModel extends HiveObject {
  @HiveField(0)
  final String arxivId;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final List<String> authors;
  
  @HiveField(3)
  final String abstract;
  
  @HiveField(4)
  final String pdfUrl;
  
  @HiveField(5)
  final DateTime publishedDate;
  
  @HiveField(6)
  final List<String> categories;
}

@HiveType(typeId: 1)
class ChatSessionModel extends HiveObject {
  @HiveField(0)
  final String sessionId;
  
  @HiveField(1)
  final List<String> paperIds;  // Max 3
  
  @HiveField(2)
  final List<MessageModel> messages;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  final DateTime updatedAt;
}

@HiveType(typeId: 2)
class MessageModel extends HiveObject {
  @HiveField(0)
  final String role;  // 'user' | 'assistant'
  
  @HiveField(1)
  final String content;
  
  @HiveField(2)
  final List<CitationModel>? citations;
  
  @HiveField(3)
  final DateTime timestamp;
}

@HiveType(typeId: 3)
class CitationModel extends HiveObject {
  @HiveField(0)
  final String paperTitle;
  
  @HiveField(1)
  final int pageNumber;
  
  @HiveField(2)
  final String chunkText;  // Excerpt for reference
}
```

### 4.5 UI Specifications

#### 4.5.1 Screen Specifications

| Screen | Key Components | Cubit Dependencies |
|--------|----------------|-------------------|
| Search | SearchBar, PaperList, Filters | SearchCubit |
| Paper Details | MetadataCard, AbstractSection, SummaryCard, AddToChatFAB | PaperDetailsCubit, PaperSelectionCubit |
| Chat | MessageList, InputField, SlashCommandOverlay, CitationChips | ChatCubit, PaperSelectionCubit |
| Settings | ExpertiseLevelSelector, ThemeToggle, ClearDataButton | SettingsCubit |

#### 4.5.2 Design Tokens (Material 3)

```dart
// colors.dart
class AppColors {
  // Primary (Research Blue)
  static const primary = Color(0xFF1E88E5);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFD1E4FF);
  
  // Secondary (Academic Gold)
  static const secondary = Color(0xFFF9A825);
  static const onSecondary = Color(0xFF000000);
  
  // Surface colors
  static const surface = Color(0xFFFFFBFE);
  static const surfaceVariant = Color(0xFFE7E0EC);
  
  // Citation highlight
  static const citationHighlight = Color(0xFFE3F2FD);
  static const citationBorder = Color(0xFF90CAF9);
}
```

---

## 5. Backend Technical Specifications

### 5.1 Technology Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Framework | FastAPI | 0.110+ |
| Language | Python | 3.10+ |
| PDF Processing | PyMuPDF (fitz) | 1.23+ |
| Vector Database | FAISS | 1.7.4 |
| HTTP Client | httpx | 0.26+ |
| Validation | Pydantic | 2.x |
| ASGI Server | Uvicorn | 0.27+ |

### 5.1.1 Backend Dependencies and Environment

`backend/requirements.txt` must pin the implementation versions:

```txt
fastapi==0.110.3
uvicorn[standard]==0.27.1
pydantic==2.7.1
pydantic-settings==2.2.1
python-dotenv==1.0.1
PyMuPDF==1.24.3
faiss-cpu==1.7.4
numpy==1.26.4
httpx==0.27.0
google-cloud-aiplatform==1.49.0
slowapi==0.1.9
python-multipart==0.0.9
pytest==8.1.1
pytest-asyncio==0.23.6
pytest-cov==5.0.0
```

`backend/.env.example` must define:

```env
VERTEX_PROJECT_ID=your-project-id
VERTEX_LOCATION=us-central1
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
GEMINI_MODEL=gemini-1.5-pro
EMBEDDING_MODEL=text-embedding-004
FAISS_INDEX_PATH=./data/faiss_index
DEBUG=true
CORS_ORIGINS=*
```

### 5.2 Project Structure

```
backend/
├── main.py                          # FastAPI app initialization
├── requirements.txt
├── Dockerfile
├── .env.example
├── app/
│   ├── __init__.py
│   ├── config.py                    # Environment config
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/
│   │   │   ├── __init__.py
│   │   │   ├── papers.py            # /api/papers endpoints
│   │   │   ├── chat.py              # /api/chat endpoints
│   │   │   ├── summary.py           # /api/summary endpoints
│   │   │   └── health.py            # /health endpoint
│   │   └── dependencies.py          # Dependency injection
│   ├── core/
│   │   ├── __init__.py
│   │   ├── exceptions.py
│   │   └── middleware.py            # Rate limiting, CORS
│   ├── models/
│   │   ├── __init__.py
│   │   ├── paper.py
│   │   ├── chunk.py
│   │   ├── chat.py
│   │   └── requests.py              # Pydantic request models
│   ├── services/
│   │   ├── __init__.py
│   │   ├── pdf_processor.py         # PyMuPDF extraction
│   │   ├── chunker.py               # Semantic chunking
│   │   ├── embedding_service.py     # Vertex AI embeddings
│   │   ├── vector_store.py          # FAISS operations
│   │   ├── rag_service.py           # RAG orchestration
│   │   ├── summarizer.py            # Adaptive summarization
│   │   └── vertex_ai_client.py      # Gemini API client
│   └── utils/
│       ├── __init__.py
│       ├── arxiv_parser.py          # Atom/XML parsing
│       └── citation_formatter.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_pdf_processor.py
│   ├── test_chunker.py
│   ├── test_vector_store.py
│   ├── test_rag_service.py
│   └── test_api_endpoints.py
└── scripts/
    └── seed_test_data.py
```

### 5.3 Service Implementations

#### 5.3.1 PDF Processor Service

```python
# app/services/pdf_processor.py
import fitz  # PyMuPDF
from typing import List, Tuple
from dataclasses import dataclass

@dataclass
class ExtractedPage:
    page_number: int
    text: str
    
@dataclass
class ProcessedDocument:
    paper_id: str
    pages: List[ExtractedPage]
    total_pages: int

class PDFProcessor:
    """Extract text from research paper PDFs with page mapping."""
    
    def __init__(self):
        self.min_text_length = 50  # Skip pages with minimal text
    
    async def process_pdf(self, pdf_bytes: bytes, paper_id: str) -> ProcessedDocument:
        """
        Extract text from PDF maintaining page numbers for citation.
        Implementations must wrap synchronous PyMuPDF work in asyncio.to_thread.
        
        Args:
            pdf_bytes: Raw PDF binary content
            paper_id: arXiv ID for association
            
        Returns:
            ProcessedDocument with page-mapped text
        """
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        pages = []
        
        for page_num in range(len(doc)):
            page = doc.load_page(page_num)
            text = page.get_text("text")
            
            # Clean extracted text
            text = self._clean_text(text)
            
            if len(text) >= self.min_text_length:
                pages.append(ExtractedPage(
                    page_number=page_num + 1,  # 1-indexed
                    text=text
                ))
        
        doc.close()
        
        return ProcessedDocument(
            paper_id=paper_id,
            pages=pages,
            total_pages=len(doc)
        )
    
    def _clean_text(self, text: str) -> str:
        """Remove common PDF artifacts and normalize whitespace."""
        # Remove headers/footers patterns, fix hyphenation, normalize spaces
        import re
        text = re.sub(r'\s+', ' ', text)
        text = re.sub(r'-\s+', '', text)  # Fix word hyphenation
        return text.strip()
```

#### 5.3.2 Semantic Chunker

```python
# app/services/chunker.py
from typing import List
from dataclasses import dataclass

@dataclass
class Chunk:
    text: str
    paper_id: str
    page_number: int
    chunk_index: int
    start_char: int
    end_char: int

class SemanticChunker:
    """
    Chunk documents with semantic boundaries and overlap.
    Preserves page number mapping for citation generation.
    """
    
    def __init__(
        self,
        chunk_size: int = 512,      # tokens (approx 4 chars/token)
        chunk_overlap: int = 50,     # tokens
        separator: str = "\n\n"
    ):
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        self.separator = separator
        self.chars_per_token = 4  # Approximation
    
    def chunk_document(self, pages: List['ExtractedPage'], paper_id: str) -> List[Chunk]:
        """
        Create overlapping chunks from document pages.
        
        Strategy:
        1. Concatenate pages with markers
        2. Split on paragraph boundaries
        3. Merge small chunks, split large ones
        4. Add overlap between consecutive chunks
        5. Map back to source pages
        """
        chunks = []
        chunk_index = 0
        
        for page in pages:
            # Split page into paragraphs
            paragraphs = page.text.split(self.separator)
            current_chunk = ""
            
            for para in paragraphs:
                if len(current_chunk) + len(para) < self.chunk_size * self.chars_per_token:
                    current_chunk += para + " "
                else:
                    if current_chunk:
                        chunks.append(Chunk(
                            text=current_chunk.strip(),
                            paper_id=paper_id,
                            page_number=page.page_number,
                            chunk_index=chunk_index,
                            start_char=0,
                            end_char=len(current_chunk)
                        ))
                        chunk_index += 1
                    
                    # Start new chunk with overlap from previous
                    overlap_text = current_chunk[-self.chunk_overlap * self.chars_per_token:]
                    current_chunk = overlap_text + para + " "
            
            # Don't forget last chunk of page
            if current_chunk.strip():
                chunks.append(Chunk(
                    text=current_chunk.strip(),
                    paper_id=paper_id,
                    page_number=page.page_number,
                    chunk_index=chunk_index,
                    start_char=0,
                    end_char=len(current_chunk)
                ))
                chunk_index += 1
        
        return chunks
```

#### 5.3.3 Embedding Service

```python
# app/services/embedding_service.py
from typing import List
from google.cloud import aiplatform
from vertexai.language_models import TextEmbeddingModel
import numpy as np

class EmbeddingService:
    """
    Generate embeddings using Vertex AI text-embedding-004 model.
    Produces 768-dimensional vectors for semantic similarity.
    """
    
    def __init__(self, project_id: str, location: str = "us-central1"):
        aiplatform.init(project=project_id, location=location)
        self.model = TextEmbeddingModel.from_pretrained("text-embedding-004")
        self.embedding_dim = 768
    
    async def embed_texts(self, texts: List[str]) -> np.ndarray:
        """
        Generate embeddings for a batch of texts.
        
        Args:
            texts: List of text strings to embed
            
        Returns:
            numpy array of shape (len(texts), 768)
        """
        # Vertex AI batch limit is 250 texts
        batch_size = 250
        all_embeddings = []
        
        for i in range(0, len(texts), batch_size):
            batch = texts[i:i + batch_size]
            embeddings = self.model.get_embeddings(batch)
            all_embeddings.extend([e.values for e in embeddings])
        
        return np.array(all_embeddings, dtype=np.float32)
    
    async def embed_query(self, query: str) -> np.ndarray:
        """
        Generate embedding for a single query.
        Optimized for retrieval queries.
        """
        embedding = self.model.get_embeddings([query])[0]
        return np.array(embedding.values, dtype=np.float32)
```

#### 5.3.4 Vector Store (FAISS)

```python
# app/services/vector_store.py
import faiss
import numpy as np
from typing import List, Tuple, Optional
from dataclasses import dataclass
import pickle
from pathlib import Path

@dataclass
class SearchResult:
    chunk_id: str
    paper_id: str
    page_number: int
    text: str
    score: float

class VectorStore:
    """
    FAISS-based vector store for semantic similarity search.
    Uses IndexFlatIP over L2-normalized vectors for cosine similarity.
    """
    
    def __init__(
        self,
        embedding_dim: int = 768,
        index_path: Optional[Path] = None
    ):
        self.embedding_dim = embedding_dim
        self.index_path = index_path
        
        # Initialize exact cosine search over normalized vectors
        self.index = faiss.IndexFlatIP(embedding_dim)  # Inner Product (cosine sim after normalization)
        
        # Metadata storage: chunk_id -> (paper_id, page_number, text)
        self.metadata: dict = {}
        self.chunk_ids: List[str] = []
    
    def add_embeddings(
        self,
        embeddings: np.ndarray,
        chunk_ids: List[str],
        metadata: List[dict]
    ):
        """
        Add embeddings with associated metadata to the index.
        
        Args:
            embeddings: Shape (n, 768) normalized vectors
            chunk_ids: Unique identifiers for each chunk
            metadata: List of dicts with paper_id, page_number, text
        """
        # Normalize for cosine similarity
        faiss.normalize_L2(embeddings)
        
        self.index.add(embeddings)
        
        for cid, meta in zip(chunk_ids, metadata):
            self.chunk_ids.append(cid)
            self.metadata[cid] = meta
    
    def search(
        self,
        query_embedding: np.ndarray,
        paper_ids: List[str],
        top_k: int = 5,
        score_threshold: float = 0.3
    ) -> List[SearchResult]:
        """
        Search for similar chunks, filtered by paper IDs.
        
        Args:
            query_embedding: Shape (768,) normalized query vector
            paper_ids: Filter results to these papers only
            top_k: Number of results to return
            
        Returns:
            List of SearchResult ordered by relevance
        """
        # Normalize query
        query = query_embedding.reshape(1, -1).astype(np.float32)
        faiss.normalize_L2(query)
        
        # Search more than top_k to account for filtering
        search_k = top_k * 10
        scores, indices = self.index.search(query, search_k)
        
        results = []
        for score, idx in zip(scores[0], indices[0]):
            if idx < 0:  # FAISS returns -1 for missing results
                continue
            
            chunk_id = self.chunk_ids[idx]
            meta = self.metadata[chunk_id]
            
            # Filter by paper_ids and minimum score
            if meta['paper_id'] not in paper_ids or score < score_threshold:
                continue
            
            results.append(SearchResult(
                chunk_id=chunk_id,
                paper_id=meta['paper_id'],
                page_number=meta['page_number'],
                text=meta['text'],
                score=float(score)
            ))
            
            if len(results) >= top_k:
                break
        
        return results
    
    def save(self):
        """Persist index and metadata to disk."""
        if self.index_path:
            faiss.write_index(self.index, str(self.index_path / "index.faiss"))
            with open(self.index_path / "metadata.pkl", 'wb') as f:
                pickle.dump({
                    'metadata': self.metadata,
                    'chunk_ids': self.chunk_ids
                }, f)
    
    def load(self):
        """Load index and metadata from disk."""
        if self.index_path and (self.index_path / "index.faiss").exists():
            self.index = faiss.read_index(str(self.index_path / "index.faiss"))
            with open(self.index_path / "metadata.pkl", 'rb') as f:
                data = pickle.load(f)
                self.metadata = data['metadata']
                self.chunk_ids = data['chunk_ids']
```

#### 5.3.5 RAG Service

```python
# app/services/rag_service.py
from typing import List
from dataclasses import dataclass
from .vector_store import VectorStore, SearchResult
from .embedding_service import EmbeddingService
from .vertex_ai_client import VertexAIClient

@dataclass
class Citation:
    paper_title: str
    page_number: int
    excerpt: str

@dataclass
class RAGResponse:
    text: str
    citations: List[Citation]

class RAGService:
    """
    Retrieval Augmented Generation pipeline.
    Retrieves relevant chunks, constructs context-aware prompts,
    and generates citation-backed responses.
    """
    
    def __init__(
        self,
        vector_store: VectorStore,
        embedding_service: EmbeddingService,
        llm_client: VertexAIClient,
        top_k: int = 5
    ):
        self.vector_store = vector_store
        self.embedding_service = embedding_service
        self.llm_client = llm_client
        self.top_k = top_k
    
    async def query(
        self,
        question: str,
        paper_ids: List[str],
        paper_titles: dict  # paper_id -> title mapping
    ) -> RAGResponse:
        """
        Process a user question using RAG pipeline.
        
        Pipeline:
        1. Embed the query
        2. Retrieve relevant chunks from selected papers
        3. Construct prompt with context
        4. Generate response with citations
        
        Args:
            question: User's natural language question
            paper_ids: List of arXiv IDs to search within
            paper_titles: Mapping of paper_id to paper title for citations
            
        Returns:
            RAGResponse with answer text and citations
        """
        # Step 1: Embed query
        query_embedding = await self.embedding_service.embed_query(question)
        
        # Step 2: Retrieve relevant chunks
        search_results = self.vector_store.search(
            query_embedding=query_embedding,
            paper_ids=paper_ids,
            top_k=self.top_k
        )
        
        if not search_results:
            return RAGResponse(
                text="I couldn't find relevant information in the selected papers to answer your question.",
                citations=[]
            )
        
        # Step 3: Construct prompt
        context = self._build_context(search_results, paper_titles)
        prompt = self._build_prompt(question, context)
        
        # Step 4: Generate response
        response_text = await self.llm_client.generate(prompt)
        
        # Step 5: Extract and format citations
        citations = self._extract_citations(search_results, paper_titles)
        
        return RAGResponse(
            text=response_text,
            citations=citations
        )
    
    def _build_context(
        self,
        results: List[SearchResult],
        paper_titles: dict
    ) -> str:
        """Format retrieved chunks as numbered context."""
        context_parts = []
        for i, result in enumerate(results, 1):
            title = paper_titles.get(result.paper_id, "Unknown Paper")
            context_parts.append(
                f"[{i}] From \"{title}\" (Page {result.page_number}):\n{result.text}"
            )
        return "\n\n".join(context_parts)
    
    def _build_prompt(self, question: str, context: str) -> str:
        """Construct the full prompt for the LLM."""
        return f"""You are a research assistant helping answer questions about academic papers.
Use ONLY the provided context to answer the question. If the context doesn't contain enough information, say so.
Always cite your sources using [Paper Title, Page N] format inline in your response.

CONTEXT:
{context}

QUESTION: {question}

ANSWER (with inline citations):"""

    def _extract_citations(
        self,
        results: List[SearchResult],
        paper_titles: dict
    ) -> List[Citation]:
        """Create citation objects from search results."""
        seen = set()
        citations = []
        
        for result in results:
            key = (result.paper_id, result.page_number)
            if key not in seen:
                seen.add(key)
                citations.append(Citation(
                    paper_title=paper_titles.get(result.paper_id, "Unknown"),
                    page_number=result.page_number,
                    excerpt=result.text[:200] + "..."
                ))
        
        return citations
```

#### 5.3.6 Summarizer Service

```python
# app/services/summarizer.py
from enum import Enum
from typing import Optional
from .vertex_ai_client import VertexAIClient

class ExpertiseLevel(str, Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    EXPERT = "expert"

class SummarizerService:
    """
    Generate adaptive summaries based on user expertise level.
    Adjusts vocabulary, depth, and examples accordingly.
    """
    
    PROMPTS = {
        ExpertiseLevel.BEGINNER: """You are explaining a research paper to someone new to the field.
Use simple language, avoid jargon (or explain it when necessary), and use analogies.
Focus on: What problem does this solve? Why does it matter? What's the main idea?

Paper Content:
{content}

Generate a beginner-friendly summary in 3-4 paragraphs.""",

        ExpertiseLevel.INTERMEDIATE: """You are explaining a research paper to a graduate student or practitioner.
Balance technical accuracy with accessibility. Include methodology overview.
Focus on: Problem statement, proposed solution, key contributions, experimental results.

Paper Content:
{content}

Generate an intermediate-level summary covering methodology and results.""",

        ExpertiseLevel.EXPERT: """You are writing a technical summary for a domain expert.
Be concise and technical. Focus on novel contributions and methodological details.
Highlight: Technical innovations, experimental setup, quantitative results, limitations.

Paper Content:
{content}

Generate an expert-level technical summary."""
    }
    
    def __init__(self, llm_client: VertexAIClient):
        self.llm_client = llm_client
    
    async def summarize(
        self,
        content: str,
        level: ExpertiseLevel = ExpertiseLevel.INTERMEDIATE
    ) -> str:
        """
        Generate summary at specified expertise level.
        
        Args:
            content: Full paper text or abstract
            level: Target expertise level
            
        Returns:
            Summary string tailored to expertise level
        """
        prompt = self.PROMPTS[level].format(content=content[:8000])  # Token limit
        return await self.llm_client.generate(prompt)
```

### 5.4 API Endpoint Definitions

```python
# app/api/routes/chat.py
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from typing import Dict, List, Optional
from app.services.rag_service import RAGService
from app.api.dependencies import get_rag_service

router = APIRouter(prefix="/api/chat", tags=["Chat"])

class ChatRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=2000)
    paper_ids: List[str] = Field(..., min_items=1, max_items=3)
    paper_titles: Dict[str, str]
    session_id: Optional[str] = None

class CitationResponse(BaseModel):
    paper_title: str
    page_number: int
    excerpt: str

class ChatResponse(BaseModel):
    text: str
    citations: List[CitationResponse]
    session_id: str

@router.post("/query", response_model=ChatResponse)
async def chat_query(
    request: ChatRequest,
    rag_service: RAGService = Depends(get_rag_service)
):
    """
    Process a chat query using RAG pipeline.
    
    - **question**: User's natural language question
    - **paper_ids**: List of arXiv IDs (max 3) to search within
    - **paper_titles**: Mapping of arXiv IDs to titles for citation labels
    - **session_id**: Optional session ID for context continuity
    """
    try:
        result = await rag_service.query(
            question=request.question,
            paper_ids=request.paper_ids,
            paper_titles=request.paper_titles
        )
        return ChatResponse(
            text=result.text,
            citations=[
                CitationResponse(
                    paper_title=c.paper_title,
                    page_number=c.page_number,
                    excerpt=c.excerpt
                ) for c in result.citations
            ],
            session_id=request.session_id or generate_session_id()
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

---

## 6. AI/ML Pipeline

### 6.1 RAG Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         RAG PIPELINE FLOW                                │
└──────────────────────────────────────────────────────────────────────────┘

  ┌─────────────┐     ┌──────────────────────────────────────────────────┐
  │ User Query  │────▶│              RETRIEVAL PHASE                      │
  └─────────────┘     │  ┌────────────────┐    ┌────────────────────┐    │
                      │  │ Query Embedding │───▶│ FAISS Similarity   │    │
                      │  │ (text-embed-004)│    │ Search (cosine)    │    │
                      │  └────────────────┘    └─────────┬──────────┘    │
                      │                                  │               │
                      │                    ┌─────────────▼────────────┐  │
                      │                    │ Filter by paper_ids     │  │
                      │                    │ Return top-k chunks     │  │
                      │                    └─────────────┬────────────┘  │
                      └──────────────────────────────────┬───────────────┘
                                                         │
                                                         ▼
                      ┌──────────────────────────────────────────────────┐
                      │              AUGMENTATION PHASE                   │
                      │  ┌────────────────────────────────────────────┐  │
                      │  │            Context Construction             │  │
                      │  │  [1] "Paper A" (Page 3): chunk text...     │  │
                      │  │  [2] "Paper A" (Page 7): chunk text...     │  │
                      │  │  [3] "Paper B" (Page 2): chunk text...     │  │
                      │  └─────────────────────┬──────────────────────┘  │
                      │                        │                         │
                      │  ┌─────────────────────▼──────────────────────┐  │
                      │  │           Prompt Template                   │  │
                      │  │  System: You are a research assistant...    │  │
                      │  │  Context: {retrieved_chunks}                │  │
                      │  │  Question: {user_query}                     │  │
                      │  │  Answer with citations:                     │  │
                      │  └─────────────────────┬──────────────────────┘  │
                      └────────────────────────┬─────────────────────────┘
                                               │
                                               ▼
                      ┌──────────────────────────────────────────────────┐
                      │               GENERATION PHASE                    │
                      │  ┌────────────────────────────────────────────┐  │
                      │  │          Vertex AI Gemini 1.5 Pro          │  │
                      │  │  - Temperature: 0.3 (factual)               │  │
                      │  │  - Max tokens: 2048                         │  │
                      │  │  - Stop sequences: None                     │  │
                      │  └─────────────────────┬──────────────────────┘  │
                      │                        │                         │
                      │  ┌─────────────────────▼──────────────────────┐  │
                      │  │         Response with Citations             │  │
                      │  │  "The paper proposes... [Paper A, Page 3]  │  │
                      │  │   Furthermore... [Paper B, Page 2]"        │  │
                      │  └────────────────────────────────────────────┘  │
                      └──────────────────────────────────────────────────┘
```

### 6.2 Embedding Model Configuration

| Parameter | Value |
|-----------|-------|
| Model | text-embedding-004 |
| Dimension | 768 |
| Max Input Tokens | 2048 |
| Similarity Metric | Cosine (via normalized inner product) |
| Batch Size | 250 (API limit) |

### 6.3 Chunking Strategy

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Chunk Size | 512 tokens (~2048 chars) | Balance between context and specificity |
| Overlap | 50 tokens (~200 chars) | Preserve context at boundaries |
| Split Strategy | Paragraph-aware | Maintain semantic coherence |
| Min Chunk Size | 100 chars | Skip trivial fragments |

### 6.4 Retrieval Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Top-K | 5 | Balance relevance with context window |
| Search Expansion | 10x K | Account for paper_id filtering |
| Score Threshold | 0.3 | Filter low-confidence matches |
| Re-ranking | None (v1) | Future: Cross-encoder re-ranking |

### 6.5 Generation Model Configuration

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Model | Gemini 1.5 Pro | Best reasoning capabilities |
| Temperature | 0.3 | Factual, low creativity |
| Max Output Tokens | 2048 | Detailed responses |
| Top-P | 0.95 | Slight diversity |
| Safety Settings | Default | Academic content safe |

---

## 7. Data Models

### 7.1 Paper Entity

```typescript
interface Paper {
  arxiv_id: string;        // e.g., "2401.12345"
  title: string;
  authors: string[];       // ["First Author", "Second Author"]
  abstract: string;
  pdf_url: string;         // Direct PDF download link
  published_date: Date;
  updated_date: Date;
  categories: string[];    // ["cs.AI", "cs.LG"]
  primary_category: string;
  doi?: string;
  journal_ref?: string;
  comment?: string;        // Author comments
}
```

### 7.2 Chunk Entity

```typescript
interface Chunk {
  chunk_id: string;        // UUID
  paper_id: string;        // arXiv ID reference
  text: string;            // Chunk content
  embedding: number[];     // 768-dim vector
  page_number: number;     // Source page (1-indexed)
  chunk_index: number;     // Order within paper
  token_count: number;     // Approximate tokens
  created_at: Date;
}
```

### 7.3 Chat Session Entity

```typescript
interface ChatSession {
  session_id: string;      // UUID
  paper_ids: string[];     // Max 3 arXiv IDs
  messages: Message[];
  created_at: Date;
  updated_at: Date;
}

interface Message {
  message_id: string;
  role: 'user' | 'assistant';
  content: string;
  citations?: Citation[];
  timestamp: Date;
  slash_command?: string;  // If triggered by command
}

interface Citation {
  paper_id: string;
  paper_title: string;
  page_number: number;
  excerpt: string;         // 200 char excerpt
}
```

### 7.4 API Request/Response Schemas

```typescript
// Paper Processing Request
interface ProcessPaperRequest {
  paper_id: string;
  title: string;
  authors: string[];
  pdf_url: string;         // Backend downloads the PDF directly
}

// Paper Processing Response
interface ProcessPaperResponse {
  paper_id: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  message: string;
}

// Paper Status Response
interface PaperStatusResponse {
  paper_id: string;
  status: 'queued' | 'processing' | 'completed' | 'failed';
  chunks_indexed?: number;
  error?: string;
}

// Chat Request
interface ChatRequest {
  question: string;
  paper_ids: string[];     // 1-3 IDs
  paper_titles: Record<string, string>;
  session_id?: string;
  expertise_level?: 'beginner' | 'intermediate' | 'expert';
}

// Chat Response
interface ChatResponse {
  text: string;
  citations: Citation[];
  session_id: string;
  tokens_used: number;
}

// Summary Request
interface SummaryRequest {
  paper_id: string;
  paper_title: string;
  content: string;
  level: 'beginner' | 'intermediate' | 'expert';
  focus?: 'methodology' | 'results' | 'contributions' | 'full';
}

// Slash Command Request
interface SlashCommandRequest {
  command: '/summary' | '/compare' | '/review' | '/gaps' | '/code' | '/visualize' | '/search' | '/explain';
  arguments?: string;
  paper_ids: string[];     // 1-3 IDs
  paper_titles: Record<string, string>;
  session_id?: string;
}

// Summary Response
interface SummaryResponse {
  summary: string;
  key_points: string[];
  level: string;
}
```

---

## 8. API Specifications

### 8.1 arXiv API Integration

**Base URL:** `https://export.arxiv.org/api/query`

**Request Format:**
```
GET /api/query?search_query={query}&start={start}&max_results={max}&sortBy={sortBy}&sortOrder={sortOrder}
```

**Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| search_query | string | Search expression (supports `ti:`, `au:`, `abs:`, `cat:`, `all:`) |
| start | int | Starting index (0-based) |
| max_results | int | Results per page (max 2000) |
| sortBy | string | `relevance`, `lastUpdatedDate`, `submittedDate` |
| sortOrder | string | `ascending`, `descending` |

**Response Format:** Atom/XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>ArXiv Query</title>
  <opensearch:totalResults>12345</opensearch:totalResults>
  <opensearch:startIndex>0</opensearch:startIndex>
  <opensearch:itemsPerPage>10</opensearch:itemsPerPage>
  
  <entry>
    <id>http://arxiv.org/abs/2401.12345v1</id>
    <title>Paper Title Here</title>
    <published>2024-01-15T00:00:00Z</published>
    <updated>2024-01-16T00:00:00Z</updated>
    <summary>Abstract text...</summary>
    <author><name>Author Name</name></author>
    <link href="http://arxiv.org/abs/2401.12345v1" rel="alternate"/>
    <link href="http://arxiv.org/pdf/2401.12345v1" rel="related" title="pdf"/>
    <arxiv:primary_category term="cs.AI"/>
    <category term="cs.AI"/>
    <category term="cs.LG"/>
  </entry>
</feed>
```

**Rate Limits:**
- 1 request per 3 seconds
- No authentication required
- Implement exponential backoff on 503 errors

### 8.2 Backend REST API

**Base URL:** `http://localhost:8000` in development. API routes are mounted directly under `/api`, with health routes under `/health`.

#### 8.2.1 Papers Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/papers/process` | Queue PDF processing from `pdf_url` |
| GET | `/api/papers/{paper_id}/status` | Get processing status |
| DELETE | `/api/papers/{paper_id}` | Remove paper from index |

#### 8.2.2 Chat Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/chat/query` | Send chat message |
| POST | `/api/chat/command` | Execute slash command |

#### 8.2.3 Summary Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/summary/generate` | Generate paper summary |

#### 8.2.4 Health Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Basic health check |
| GET | `/health/ready` | Readiness probe |

### 8.3 Slash Commands Specification

| Command | Parameters | Description |
|---------|------------|-------------|
| `/summary` | `[level]` | Generate summary at expertise level |
| `/compare` | None | Compare methodologies across selected papers |
| `/review` | `[focus]` | Generate literature review |
| `/gaps` | None | Identify research gaps |
| `/code` | `[language]` | Generate implementation prompts |
| `/visualize` | `[type]` | Describe visualization approach |
| `/search` | `<query>` | Semantic search within papers |
| `/explain` | `<term>` | Explain a concept from papers |

---

## 9. External Integrations

### 9.1 Google Vertex AI

**Services Used:**
1. **Gemini 1.5 Pro** - Text generation
2. **text-embedding-004** - Embeddings

**Authentication:**
- Service Account JSON key
- Environment variable: `GOOGLE_APPLICATION_CREDENTIALS`

**Configuration:**
```python
# Environment variables
VERTEX_PROJECT_ID=your-project-id
VERTEX_LOCATION=us-central1

# Model settings
GEMINI_MODEL=gemini-1.5-pro
EMBEDDING_MODEL=text-embedding-004
```

**Cost Estimation (per 1M tokens):**
- Gemini 1.5 Pro Input: $1.25
- Gemini 1.5 Pro Output: $5.00
- Embeddings: $0.025

### 9.2 arXiv API

**No authentication required.**

**Best Practices:**
- Cache responses (24-hour TTL for metadata)
- Implement retry with exponential backoff
- Use bulk queries when possible
- Respect 3-second rate limit

### 9.3 PDF Hosting (arXiv)

**Direct Download URL Pattern:**
```
https://arxiv.org/pdf/{arxiv_id}.pdf
```

**Considerations:**
- PDFs are cached on CDN
- Large files (>50MB) may timeout
- Implement streaming download

---

## 10. Security Requirements

### 10.1 Data Privacy

| Requirement | Implementation |
|-------------|----------------|
| Local chat storage | Hive encrypted boxes |
| No server-side logging | Ephemeral request processing |
| Minimal data transmission | Only query and paper IDs sent |
| User control | Local data deletion option |

### 10.2 API Security

| Layer | Mechanism |
|-------|-----------|
| Transport | TLS 1.3 mandatory |
| Authentication | API key (future: JWT) |
| Rate Limiting | Token bucket (100 req/min) |
| Input Validation | Pydantic models |
| Output Sanitization | HTML escape in responses |

### 10.3 Credential Management

| Secret | Storage |
|--------|---------|
| Vertex AI key | Environment variable |
| API keys | Secret Manager (GCP) |
| Hive encryption key | Secure storage (mobile) |

### 10.4 Compliance Considerations

- **GDPR**: No PII stored server-side
- **Academic Use**: Respect arXiv terms of service
- **AI Safety**: Content filtering via Vertex AI safety settings

---

## 11. Performance Requirements

### 11.1 Response Time Targets

| Operation | Target | P99 |
|-----------|--------|-----|
| arXiv Search | < 2s | 3s |
| AI Summary | < 8s | 12s |
| Chat Query | < 5s | 8s |
| PDF Processing | < 30s | 45s |

### 11.2 Throughput Targets

| Metric | Target |
|--------|--------|
| Concurrent users | 100 |
| Requests/second | 50 |
| Papers/day processing | 500 |

### 11.3 Scalability Requirements

| Component | Scaling Strategy |
|-----------|------------------|
| Backend | Horizontal (Kubernetes) |
| Vector Store | FAISS IVF for >1M vectors |
| Embeddings | Batch processing |
| Cache | Redis cluster |

### 11.4 Resource Limits

| Resource | Limit |
|----------|-------|
| PDF size | 50 MB |
| Chunk storage/paper | ~100 chunks |
| Chat history/session | 50 messages |
| Selected papers | 3 max |

---

## 12. Infrastructure & Deployment

### 12.1 Cloud Architecture (GCP)

```
┌─────────────────────────────────────────────────────────────────┐
│                         GOOGLE CLOUD                            │
│                                                                 │
│  ┌──────────────────┐    ┌──────────────────┐                  │
│  │   Cloud Load     │    │   Cloud Armor    │                  │
│  │   Balancer       │────│   (WAF)          │                  │
│  └────────┬─────────┘    └──────────────────┘                  │
│           │                                                     │
│  ┌────────▼─────────────────────────────────────────┐          │
│  │              Cloud Run / GKE                      │          │
│  │  ┌─────────────┐  ┌─────────────┐  ┌──────────┐  │          │
│  │  │  FastAPI    │  │  FastAPI    │  │  FastAPI │  │          │
│  │  │  Instance 1 │  │  Instance 2 │  │  Instance│  │          │
│  │  └──────┬──────┘  └──────┬──────┘  └────┬─────┘  │          │
│  └─────────┼────────────────┼───────────────┼───────┘          │
│            │                │               │                   │
│  ┌─────────▼────────────────▼───────────────▼───────┐          │
│  │                  Shared Services                  │          │
│  │  ┌─────────────┐  ┌─────────────┐  ┌──────────┐  │          │
│  │  │   FAISS     │  │   Redis     │  │  Cloud   │  │          │
│  │  │   (GCS)     │  │   Cache     │  │  Storage │  │          │
│  │  └─────────────┘  └─────────────┘  └──────────┘  │          │
│  └───────────────────────────────────────────────────┘          │
│                                                                 │
│  ┌───────────────────────────────────────────────────┐          │
│  │                   Vertex AI                        │          │
│  │  ┌─────────────────┐  ┌─────────────────────────┐ │          │
│  │  │ Gemini 1.5 Pro  │  │ text-embedding-004      │ │          │
│  │  └─────────────────┘  └─────────────────────────┘ │          │
│  └───────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

### 12.2 Environment Configuration

**Development:**
```yaml
# docker-compose.dev.yml
services:
  api:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - DEBUG=true
      - VERTEX_PROJECT_ID=${VERTEX_PROJECT_ID}
    volumes:
      - ./backend:/app
      - ./data:/data
```

**Production:**
```yaml
# Cloud Run service.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: research-assistant-api
spec:
  template:
    spec:
      containers:
        - image: gcr.io/${PROJECT_ID}/api:latest
          resources:
            limits:
              cpu: "2"
              memory: "4Gi"
          env:
            - name: VERTEX_PROJECT_ID
              valueFrom:
                secretKeyRef:
                  name: vertex-config
                  key: project_id
```

### 12.3 CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: pytest tests/

  deploy-backend:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Build and push
        run: |
          docker build -t gcr.io/$PROJECT/api:$SHA .
          docker push gcr.io/$PROJECT/api:$SHA
      - name: Deploy to Cloud Run
        run: |
          gcloud run deploy research-api \
            --image gcr.io/$PROJECT/api:$SHA \
            --region us-central1

  deploy-mobile:
    needs: test
    runs-on: macos-latest
    steps:
      - name: Build Flutter
        run: flutter build apk --release
      - name: Upload to Play Console
        uses: r0adkll/upload-google-play@v1
```

---

## 13. Testing Strategy

### 13.1 Test Pyramid

```
                    ┌───────────────┐
                    │   E2E Tests   │  10%
                    │  (Appium)     │
                    └───────────────┘
               ┌─────────────────────────┐
               │   Integration Tests     │  30%
               │   (API, RAG Pipeline)   │
               └─────────────────────────┘
          ┌───────────────────────────────────┐
          │         Unit Tests                │  60%
          │  (Services, Cubits, Models)       │
          └───────────────────────────────────┘
```

### 13.2 Test Categories

#### Frontend (Flutter)

| Type | Framework | Coverage Target |
|------|-----------|-----------------|
| Unit | flutter_test | 80% |
| Widget | flutter_test | 70% |
| Integration | integration_test | Key flows |
| Golden | golden_toolkit | UI components |

#### Backend (FastAPI)

| Type | Framework | Coverage Target |
|------|-----------|-----------------|
| Unit | pytest | 85% |
| Integration | pytest + httpx | API endpoints |
| Load | locust | Performance SLAs |

### 13.3 Key Test Scenarios

**RAG Pipeline Tests:**
1. Embedding generation consistency
2. FAISS index add/search operations
3. Citation extraction accuracy
4. Multi-paper context handling

**Integration Tests:**
1. arXiv API response parsing
2. PDF processing pipeline
3. End-to-end chat flow
4. Slash command execution

---

## 14. Appendices

### 14.1 Glossary

| Term | Definition |
|------|------------|
| RAG | Retrieval Augmented Generation - combining retrieval with LLM generation |
| Embedding | Dense vector representation of text for similarity search |
| Chunk | Segment of document text with maintained page mapping |
| FAISS | Facebook AI Similarity Search - efficient vector indexing |
| arXiv | Open-access repository for scientific preprints |
| Cubit | Lightweight BLoC-based state management class |

### 14.2 Reference Documents

1. [arXiv API User Manual](https://arxiv.org/help/api/user-manual)
2. [Vertex AI Documentation](https://cloud.google.com/vertex-ai/docs)
3. [FAISS Wiki](https://github.com/facebookresearch/faiss/wiki)
4. [Flutter BLoC Documentation](https://bloclibrary.dev)
5. [FastAPI Documentation](https://fastapi.tiangolo.com)

### 14.3 Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01 | FAISS over Pinecone | Cost, self-hosted control |
| 2026-01 | Gemini 1.5 Pro | Best reasoning for citations |
| 2026-01 | Hive over SQLite | Flutter-native, typed |
| 2026-01 | 3-paper limit | Context window management |
| 2026-02 | 512-token chunks | Balance precision/recall |

### 14.4 Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Apr 2026 | - | Initial TRD |
| 1.1 | Apr 2026 | - | Added implementation-ready phases, dependency pins, API alignment, and verification plan |

---

## 15. Implementation Roadmap

The project root (`/Users/lkrjangid/Desktop/college_project`) is the Flutter project root. The FastAPI backend lives under `backend/`.

### 15.1 Backend Implementation Phases

| Phase | Goal | Required Outputs |
|-------|------|------------------|
| 1 | Backend scaffolding and configuration | `backend/requirements.txt`, `.env.example`, `app/config.py`, core exception mapper, CORS and SlowAPI rate limiting |
| 2 | Backend models | `PaperMetadata`, `ProcessingStatus`, `PaperStatus`, document/chunk dataclasses, `Citation`, `RAGResponse`, and request/response schemas |
| 3 | Leaf services | PDF extraction, paragraph-aware chunking, Vertex AI generation client, embedding service, FAISS vector store, citation formatter |
| 4 | Composite services | `RAGService` for retrieval and slash commands, `SummarizerService` with beginner/intermediate/expert prompts |
| 5 | API layer and entry point | DI singletons, in-memory paper status store, health, papers, chat, summary routes, FastAPI lifespan load/save for FAISS, Dockerfile |
| 6 | Backend tests | Pytest coverage for PDF processing, chunking, vector store, RAG service, API endpoints, and `scripts/seed_test_data.py` smoke script |

### 15.2 Flutter Implementation Phases

| Phase | Goal | Required Outputs |
|-------|------|------------------|
| 7 | Flutter scaffold | `flutter create` at repo root and dependency updates in `pubspec.yaml` |
| 8 | Core infrastructure | API constants, app constants, Hive keys, Material 3 themes, network exceptions, two Dio clients, arXiv rate-limit interceptor, XML/date utilities, GetIt shell |
| 9 | Domain layer | Pure entities, abstract repositories, and use cases for search, summary, chat, and slash commands |
| 10 | Data layer | Hive models/type adapters, remote/local datasources, repository implementations, DI registrations, generated `.g.dart` files |
| 11 | Cubits | Search, paper selection, paper details, chat, and settings cubits with explicit state classes |
| 12 | App shell | Named routes, `MultiBlocProvider`, theme switching, Hive initialization, adapter registration, box opening, dependency initialization |
| 13 | UI pages and widgets | Loading overlay, selection bar, search page, paper details page, chat page with slash overlay, settings page |
| 14 | Polish and error handling | Cached search fallback, empty states, shimmer loading states, retry actions, rate-limit/server-specific messages |
| 15 | Flutter tests | XML parser, cubit flows, paper repository implementation, and chat/slash command tests |

### 15.3 Key Implementation Decisions

| Decision | Requirement |
|----------|-------------|
| Backend downloads PDFs by URL | `ProcessPaperRequest` sends `paper_id`, `title`, `authors`, and `pdf_url`; the mobile app must not upload PDF blobs |
| Background PDF processing | `/api/papers/process` returns immediately and the client polls `/api/papers/{paper_id}/status` |
| In-memory status store | Acceptable for the college-project scope; production can replace it with Redis |
| FAISS deletion by rebuild | `IndexFlatIP` does not support direct delete for this design; `remove_paper()` rebuilds the index |
| Separate Dio clients | arXiv rate limiting must not delay backend calls |
| Cubit scope | `PaperSelectionCubit` and `SettingsCubit` are global; search, paper details, and chat cubits are page-scoped |
| Repository results | Repository methods return `Either<Failure, T>` so UI error handling is explicit |
| Local-only chat history | Hive stores chat sessions on-device; backend receives only question, selected paper IDs, paper titles, and optional session ID |

### 15.4 Verification Commands

Backend verification:

```bash
cd backend
pip install -r requirements.txt
python -c "from app.config import get_settings"
pytest tests/ -v
uvicorn main:app --reload --port 8000
```

Flutter verification:

```bash
flutter analyze
flutter test
flutter run
```

End-to-end smoke flow:

1. Start backend with `cd backend && uvicorn main:app --reload --port 8000`.
2. Run the mobile app with `flutter run`.
3. Search arXiv for `attention mechanism`.
4. Open paper details and confirm metadata renders.
5. Add one to three papers and confirm the selection bar appears.
6. Open chat and ask a paper-specific question.
7. Confirm the RAG response includes citations.
8. Run a slash command such as `/summary intermediate`.
9. Toggle dark mode in settings.
10. Disable network and confirm cached search results and local chat history remain accessible.

---

*End of Technical Requirements Document*
