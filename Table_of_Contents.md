---
title: "Table of Contents"
subtitle: "AI-Powered Research Paper Search, Summarization and Chat Assistant"
mainfont: "Times New Roman"
fontsize: 12pt
linestretch: 1.5
geometry:
  - top=1in
  - bottom=1in
  - right=1in
  - left=1.5in
  - a4paper
---

# Table of Contents

| S. No  | Table of Content                                | Page No |
|:------:|:------------------------------------------------|:-------:|
|        | **ACKNOWLEDGEMENT**                             |         |
|        | **DECLARATION**                                 |         |
|        | **CERTIFICATE**                                 |         |
|        | **LIST OF FIGURES**                             |         |
|        | **LIST OF TABLES**                              |         |
| **1**  | **INTRODUCTION**                                |         |
| 1.1    | Background                                      |         |
| 1.2    | Problem Statement                               |         |
| 1.3    | Project Introduction                            |         |
| 1.4    | Key Innovations                                 |         |
| 1.5    | Document Structure                              |         |
| **2**  | **OBJECTIVE**                                   |         |
| 2.1    | Primary Objective                               |         |
| 2.2    | Secondary Objectives                            |         |
| 2.3    | Out-of-Scope Items                              |         |
| **3**  | **SYSTEM ANALYSIS**                             |         |
| 3.1    | Identification of Need                          |         |
| 3.2    | Preliminary Investigation                       |         |
| 3.3    | Feasibility Study                               |         |
| 3.3.1  | Technical Feasibility                           |         |
| 3.3.2  | Operational Feasibility                         |         |
| 3.3.3  | Economic Feasibility                            |         |
| 3.4    | Project Planning                                |         |
| 3.4.1  | Methodology                                     |         |
| 3.4.2  | Deliverables per Phase                          |         |
| 3.4.3  | Risk Register                                   |         |
| 3.5    | Project Scheduling                              |         |
| 3.5.1  | Gantt Chart                                     |         |
| 3.5.2  | PERT Chart                                      |         |
| 3.6    | Software Requirement Specification              |         |
| 3.6.1  | Functional Requirements                         |         |
| 3.6.2  | Non-Functional Requirements                     |         |
| 3.7    | System Specification                            |         |
| 3.7.1  | Hardware Requirements (Development)             |         |
| 3.7.2  | Hardware Requirements (Production)              |         |
| 3.7.3  | Software Requirements                           |         |
| 3.8    | Data Models                                     |         |
| 3.8.1  | Class Diagram                                   |         |
| 3.8.2  | Activity Diagram — RAG Query Flow               |         |
| 3.8.3  | Sequence Diagram — Chat Send                    |         |
| 3.8.4  | Entity-Relationship Diagram                     |         |
| 3.8.5  | Use-Case Diagram                                |         |
| 3.8.6  | Data-Flow Diagram (Level 0 and Level 1)         |         |
| **4**  | **SYSTEM DESIGN**                               |         |
| 4.1    | Modularization Details                          |         |
| 4.1.1  | Flutter Client — Layered Decomposition          |         |
| 4.1.2  | Backend — Service Decomposition                 |         |
| 4.1.3  | File-by-File Responsibilities (Backend)         |         |
| 4.1.4  | File-by-File Responsibilities (Flutter)         |         |
| 4.2    | Data Integrity and Constraints                  |         |
| 4.2.1  | Hive Type-ID Stability                          |         |
| 4.2.2  | Maximum Three Papers per Chat Session           |         |
| 4.2.3  | FAISS L2-Normalisation                          |         |
| 4.2.4  | Citation Grounding                              |         |
| 4.2.5  | 50 MB PDF Cap                                   |         |
| 4.2.6  | arXiv Rate Limit (1 req / 3 s)                  |         |
| 4.2.7  | Hash-Based PDF Deduplication                    |         |
| **5**  | **TESTING**                                     |         |
| 5.1    | Testing Strategy                                |         |
| 5.2    | Test Inventory                                  |         |
| 5.3    | Selected Test Cases                             |         |
| 5.4    | RAG Quality Testing                             |         |
| 5.5    | Performance Benchmarks                          |         |
| 5.6    | Defect Density and Regression                   |         |
| **6**  | **SYSTEM SECURITY MEASURES**                    |         |
| 6.1    | Local-First Privacy                             |         |
| 6.2    | Transport Security                              |         |
| 6.3    | Credential Management                           |         |
| 6.4    | Rate Limiting                                   |         |
| 6.5    | Input Validation                                |         |
| 6.6    | CORS                                            |         |
| 6.7    | PDF Hash Deduplication                          |         |
| 6.8    | No PII Logging                                  |         |
| 6.9    | Threat Model Summary                            |         |
| **7**  | **COST ESTIMATION**                             |         |
| 7.1    | Lines of Code (KLOC)                            |         |
| 7.2    | COCOMO Basic — Organic Mode                     |         |
| 7.3    | Development Cost (Indicative)                   |         |
| 7.4    | Recurring Runtime Cost                          |         |
| 7.5    | Total Cost of Ownership                         |         |
| **8**  | **REPORT (OUTPUT)**                             |         |
| 8.1    | Search Screen                                   |         |
| 8.2    | Paper Details Screen                            |         |
| 8.3    | Chat Screen                                     |         |
| 8.4    | Slash Command Overlay                           |         |
| 8.5    | Chat History Screen                             |         |
| 8.6    | Settings Screen                                 |         |
| 8.7    | PDF Upload Flow                                 |         |
| 8.8    | Error and Empty States                          |         |
| **9**  | **FUTURE SCOPE**                                |         |
| 9.1    | Multi-Modal Indexing                            |         |
| 9.2    | Offline-Capable Language Model                  |         |
| 9.3    | Additional Paper Sources                        |         |
| 9.4    | Citation Export (BibTeX / RIS)                  |         |
| 9.5    | Team Workspaces                                 |         |
| 9.6    | Figure-Aware Citations                          |         |
| 9.7    | Re-Ranking Stage                                |         |
| 9.8    | Adaptive Chunk Size                             |         |
| **10** | **APPENDICES**                                  |         |
| 10.1   | Coding Appendix                                 |         |
| 10.1.1 | File Index — Flutter (`lib/`)                   |         |
| 10.1.2 | File Index — Backend (`backend/`)               |         |
| 10.1.3 | Selected Code Excerpts                          |         |
| 10.2   | Bibliography                                    |         |

\newpage

# List of Figures

| Figure No. | Title                                                                |
|:----------:|:---------------------------------------------------------------------|
| 3.1        | Gantt chart of the five-phase project schedule                       |
| 3.2        | PERT chart with three-point estimates                                |
| 3.3        | Class diagram showing entities, repositories, cubits and RAG services|
| 3.4        | Activity diagram of the RAG query flow                               |
| 3.5        | Sequence diagram of a non-slash chat message round trip              |
| 3.6        | Entity-relationship diagram                                          |
| 3.7        | Use-case diagram with one human actor and thirteen use cases         |
| 3.8        | Data-Flow Diagram, Level 0 (Context)                                 |
| 3.9        | Data-Flow Diagram, Level 1                                           |
| 4.1        | Layered decomposition of the Flutter client                          |
| 4.2        | Backend module decomposition                                         |
| 8.1        | Search screen                                                        |
| 8.2        | Paper details screen                                                 |
| 8.3        | Chat screen with citations                                           |
| 8.4        | Slash command overlay                                                |
| 8.5        | Chat history screen                                                  |
| 8.6        | Settings screen                                                      |
| 8.7        | PDF upload progress                                                  |

\newpage

# List of Tables

| Table No. | Title                                                                |
|:---------:|:---------------------------------------------------------------------|
| 2.1       | Mapping of secondary objectives to code artefacts                    |
| 3.1       | Comparison of existing tools with the proposed system                |
| 3.2       | Phase-wise deliverables                                              |
| 3.3       | Risk register                                                        |
| 3.4       | Functional requirements with their realisation in code               |
| 3.5       | Non-functional requirements with measurable acceptance criteria      |
| 3.6       | Software stack                                                       |
| 4.1       | Backend file-by-file responsibilities                                |
| 4.2       | Selected Flutter files and their responsibilities                    |
| 4.3       | Frozen Hive type-IDs                                                 |
| 5.1       | Test files in the repository                                         |
| 5.2       | Twenty representative test cases across the test suites              |
| 5.3       | Measured performance against the NFR targets                         |
| 6.1       | Threat model                                                         |
| 7.1       | KLOC count from the repository                                       |
| 7.2       | COCOMO Basic Organic estimate                                        |
| 7.3       | Indicative Vertex AI pricing                                         |
| 7.4       | Per-user runtime cost projection                                     |
| 7.5       | Total cost of ownership, year one, single user                       |
| 8.1       | Slash command catalogue                                              |
