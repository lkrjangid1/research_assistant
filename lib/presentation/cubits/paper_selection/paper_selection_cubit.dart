import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/hive_keys.dart';
import '../../../domain/repositories/paper_repository.dart';
import '../../../data/models/paper_model.dart';
import 'paper_selection_state.dart';
import '../../../domain/entities/paper.dart';

class PaperSelectionCubit extends Cubit<PaperSelectionState> {
  final PaperRepository _paperRepository;

  PaperSelectionCubit(this._paperRepository) : super(PaperSelectionState.initial());

  Future<void> addPaper(Paper paper) async {
    if (state.selectedPapers.length >= AppConstants.maxPapersPerSession) {
      emit(state.copyWith(error: 'Maximum ${AppConstants.maxPapersPerSession} papers allowed'));
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
      error: null,
    ));

    // Skip re-indexing if the backend already has this paper
    final statusResult = await _paperRepository.getPaperStatus(paper.arxivId);
    final existingStatus = statusResult.fold(
      (failure) => null,
      (status) => (status['status'] as String?)?.toLowerCase(),
    );

    if (existingStatus == 'completed') {
      emit(state.copyWith(
        paperStatuses: Map<String, String>.from(state.paperStatuses)
          ..[paper.arxivId] = 'completed',
        error: null,
      ));
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
    emit(state.copyWith(
      selectedPapers: state.selectedPapers.where((p) => p.arxivId != arxivId).toList(),
      paperStatuses: nextStatuses,
      error: null,
    ));
  }

  void clearAll() => emit(PaperSelectionState.initial());

  bool isSelected(String arxivId) => state.selectedPapers.any((p) => p.arxivId == arxivId);

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
          final statusValue = (status['status'] as String? ?? 'processing').toLowerCase();
          final nextStatuses = Map<String, String>.from(state.paperStatuses)
            ..[paperId] = statusValue;
          emit(state.copyWith(paperStatuses: nextStatuses, error: null));

          if (statusValue == 'completed') {
            return true;
          }
          if (statusValue == 'failed') {
            final message = status['error_message'] as String? ?? 'Paper indexing failed';
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
    emit(state.copyWith(
      paperStatuses: nextStatuses,
      error: message,
    ));
  }
}
