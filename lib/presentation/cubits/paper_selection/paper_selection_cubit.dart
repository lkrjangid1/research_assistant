import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/hive_keys.dart';
import '../../../domain/repositories/paper_repository.dart';
import '../../../data/models/paper_model.dart';
import 'paper_selection_state.dart';
import '../../../domain/entities/paper.dart';

class PaperSelectionCubit extends Cubit<PaperSelectionState> {
  final PaperRepository _paperRepository;
  final Set<String> _sizeLookupsInFlight = <String>{};
  static const _uploadedPaperAbstract =
      'User-uploaded PDF indexed for chat. Ask questions in chat to explore the full document.';

  PaperSelectionCubit(this._paperRepository)
      : super(PaperSelectionState.initial());

  Future<Paper?> uploadPdf({
    required String filename,
    required List<int> pdfBytes,
  }) async {
    if (state.selectedPapers.length >= AppConstants.maxPapersPerSession) {
      emit(state.copyWith(
          error: 'Maximum ${AppConstants.maxPapersPerSession} papers allowed'));
      return null;
    }

    final uploadResult = await _paperRepository.uploadPaperPdf(
      pdfBytes: pdfBytes,
      filename: filename,
    );

    return await uploadResult.fold(
      (failure) async {
        emit(state.copyWith(error: failure.message));
        return null;
      },
      (data) async {
        final paperId = data['paper_id'] as String;
        Paper? existingPaper;
        for (final paper in state.selectedPapers) {
          if (paper.arxivId == paperId) {
            existingPaper = paper;
            break;
          }
        }
        if (existingPaper != null) {
          return existingPaper;
        }

        final paper = Paper(
          arxivId: paperId,
          title: (data['title'] as String?)?.trim().isNotEmpty == true
              ? data['title'] as String
              : filename.replaceFirst(
                  RegExp(r'\.pdf$', caseSensitive: false), ''),
          authors: const [],
          abstract: _uploadedPaperAbstract,
          pdfUrl: '${ApiConstants.backendBaseUrl}${data['pdf_url'] as String}',
          publishedDate: DateTime.now(),
          categories: const ['Uploaded PDF'],
          pdfSizeBytes:
              (data['pdf_size_bytes'] as num?)?.toInt() ?? pdfBytes.length,
        );
        await addPaper(paper);
        return paper;
      },
    );
  }

  Future<void> addPaper(Paper paper) async {
    if (state.selectedPapers.length >= AppConstants.maxPapersPerSession) {
      emit(state.copyWith(
          error: 'Maximum ${AppConstants.maxPapersPerSession} papers allowed'));
      return;
    }
    if (state.selectedPapers.any((p) => p.arxivId == paper.arxivId)) return;

    // Cache full Paper entity so historical chat sessions can reconstruct it
    Hive.box<PaperModel>(HiveKeys.papersBox)
        .put(paper.arxivId, PaperModel.fromEntity(paper));

    final nextPapers = [...state.selectedPapers, paper];

    // Show processing immediately so the UI responds without delay
    emit(state.copyWith(
      selectedPapers: nextPapers,
      paperStatuses: Map<String, String>.from(state.paperStatuses)
        ..[paper.arxivId] = 'processing',
      paperProgress: Map<String, PaperIndexingProgress>.from(
        state.paperProgress,
      )..[paper.arxivId] = PaperIndexingProgress(
          status: 'processing',
          currentStep: 'queued',
          pdfSizeBytes: paper.pdfSizeBytes,
        ),
      error: null,
    ));

    if (paper.pdfSizeBytes == null) {
      unawaited(ensurePdfSize(paper));
    }

    // Skip re-indexing if the backend already has this paper
    final statusResult = await _paperRepository.getPaperStatus(paper.arxivId);
    String? existingStatus;
    statusResult.fold(
      (failure) => null,
      (status) {
        existingStatus = _applyStatusPayload(paper.arxivId, status);
        return null;
      },
    );

    if (existingStatus == 'completed') {
      return;
    }

    if (existingStatus == 'processing') {
      // Backend is already working on it — just wait
      await _pollUntilReady(paper.arxivId);
      return;
    }

    // Not indexed yet — trigger full processing
    final processResult = await _paperRepository.processPaper(
      arxivId: paper.arxivId,
      title: paper.title,
      authors: paper.authors,
      pdfUrl: paper.pdfUrl,
    );

    await processResult.fold(
      (failure) async {
        _markFailure(paper.arxivId, failure.message);
      },
      (_) => _pollUntilReady(paper.arxivId),
    );
  }

  void removePaper(String arxivId) {
    final nextStatuses = Map<String, String>.from(state.paperStatuses)
      ..remove(arxivId);
    final nextProgress = Map<String, PaperIndexingProgress>.from(
      state.paperProgress,
    )..remove(arxivId);
    emit(state.copyWith(
      selectedPapers:
          state.selectedPapers.where((p) => p.arxivId != arxivId).toList(),
      paperStatuses: nextStatuses,
      paperProgress: nextProgress,
      error: null,
    ));
  }

  void clearAll() => emit(PaperSelectionState.initial());

  bool isSelected(String arxivId) =>
      state.selectedPapers.any((p) => p.arxivId == arxivId);

  Map<String, String> get paperTitles =>
      {for (final p in state.selectedPapers) p.arxivId: p.title};

  Future<void> _pollUntilReady(String paperId) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      // Progressive backoff: 1s for first 3 polls (catches fast indexing),
      // then 3s up to poll 10, then 5s for the long tail (large PDF downloads).
      final delay = attempt < 3
          ? const Duration(seconds: 1)
          : attempt < 10
              ? const Duration(seconds: 3)
              : const Duration(seconds: 5);
      await Future<void>.delayed(delay);
      final result = await _paperRepository.getPaperStatus(paperId);

      final shouldStop = result.fold(
        (failure) {
          _markFailure(paperId, failure.message);
          return true;
        },
        (status) {
          final statusValue = _applyStatusPayload(paperId, status);

          if (statusValue == 'completed') {
            return true;
          }
          if (statusValue == 'failed') {
            final message =
                status['error_message'] as String? ?? 'Paper indexing failed';
            _markFailure(paperId, message);
            return true;
          }
          return false;
        },
      );

      if (shouldStop) return;
    }

    _markFailure(paperId, 'Paper indexing timed out. Please try again.');
  }

  void _markFailure(String paperId, String message) {
    final nextStatuses = Map<String, String>.from(state.paperStatuses)
      ..[paperId] = 'failed';
    final existing = state.progressFor(paperId);
    final nextProgress = Map<String, PaperIndexingProgress>.from(
      state.paperProgress,
    )..[paperId] = (existing ?? const PaperIndexingProgress()).copyWith(
        status: 'failed',
        currentStep: 'failed',
      );
    emit(state.copyWith(
      paperStatuses: nextStatuses,
      paperProgress: nextProgress,
      error: message,
    ));
  }

  Future<void> ensurePdfSize(Paper paper) async {
    final existingSize =
        state.progressFor(paper.arxivId)?.pdfSizeBytes ?? paper.pdfSizeBytes;
    if (existingSize != null || paper.pdfUrl.isEmpty) return;
    if (!_sizeLookupsInFlight.add(paper.arxivId)) return;

    final result = await _paperRepository.getPdfSize(
      pdfUrl: paper.pdfUrl,
      paperId: paper.arxivId,
    );
    _sizeLookupsInFlight.remove(paper.arxivId);

    result.fold(
      (_) => null,
      (data) {
        final size = (data['size_bytes'] as num?)?.toInt();
        if (size != null && size > 0) {
          _applyPdfSize(paper.arxivId, size);
        }
      },
    );
  }

  String _applyStatusPayload(String paperId, Map<String, dynamic> status) {
    final existing = state.progressFor(paperId);
    final selectedSize = _selectedPaper(paperId)?.pdfSizeBytes;
    final progress = PaperIndexingProgress.fromStatusJson(
      status,
      fallbackPdfSizeBytes: existing?.pdfSizeBytes ?? selectedSize,
    );
    _emitProgress(paperId, progress);
    return progress.status;
  }

  void _applyPdfSize(String paperId, int size) {
    final existing = state.progressFor(paperId);
    final progress = (existing ?? const PaperIndexingProgress()).copyWith(
      pdfSizeBytes: size,
    );
    _emitProgress(paperId, progress);
  }

  void _emitProgress(String paperId, PaperIndexingProgress progress) {
    final nextStatuses = Map<String, String>.from(state.paperStatuses)
      ..[paperId] = progress.status;
    final nextProgress = Map<String, PaperIndexingProgress>.from(
      state.paperProgress,
    )..[paperId] = progress;

    final nextPapers = state.selectedPapers.map((paper) {
      if (paper.arxivId != paperId || progress.pdfSizeBytes == null) {
        return paper;
      }
      return paper.copyWith(pdfSizeBytes: progress.pdfSizeBytes);
    }).toList();

    emit(state.copyWith(
      selectedPapers: nextPapers,
      paperStatuses: nextStatuses,
      paperProgress: nextProgress,
      error: null,
    ));
  }

  Paper? _selectedPaper(String paperId) {
    for (final paper in state.selectedPapers) {
      if (paper.arxivId == paperId) return paper;
    }
    return null;
  }
}
