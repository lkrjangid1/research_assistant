import 'package:equatable/equatable.dart';
import '../../../domain/entities/paper.dart';

class PaperIndexingProgress extends Equatable {
  final String status;
  final int totalChunks;
  final int processedChunks;
  final String currentStep;
  final int? estimatedSecondsRemaining;
  final int? pdfSizeBytes;

  const PaperIndexingProgress({
    this.status = 'idle',
    this.totalChunks = 0,
    this.processedChunks = 0,
    this.currentStep = '',
    this.estimatedSecondsRemaining,
    this.pdfSizeBytes,
  });

  factory PaperIndexingProgress.fromStatusJson(
    Map<String, dynamic> json, {
    int? fallbackPdfSizeBytes,
  }) {
    return PaperIndexingProgress(
      status: (json['status'] as String? ?? 'processing').toLowerCase(),
      totalChunks: (json['total_chunks'] as num?)?.toInt() ?? 0,
      processedChunks: (json['processed_chunks'] as num?)?.toInt() ?? 0,
      currentStep: json['current_step'] as String? ?? '',
      estimatedSecondsRemaining:
          (json['estimated_seconds_remaining'] as num?)?.toInt(),
      pdfSizeBytes:
          (json['pdf_size_bytes'] as num?)?.toInt() ?? fallbackPdfSizeBytes,
    );
  }

  PaperIndexingProgress copyWith({
    String? status,
    int? totalChunks,
    int? processedChunks,
    String? currentStep,
    int? estimatedSecondsRemaining,
    int? pdfSizeBytes,
  }) {
    return PaperIndexingProgress(
      status: status ?? this.status,
      totalChunks: totalChunks ?? this.totalChunks,
      processedChunks: processedChunks ?? this.processedChunks,
      currentStep: currentStep ?? this.currentStep,
      estimatedSecondsRemaining:
          estimatedSecondsRemaining ?? this.estimatedSecondsRemaining,
      pdfSizeBytes: pdfSizeBytes ?? this.pdfSizeBytes,
    );
  }

  int get remainingChunks {
    final remaining = totalChunks - processedChunks;
    return remaining > 0 ? remaining : 0;
  }

  double? get fraction {
    if (totalChunks <= 0) return null;
    return processedChunks.clamp(0, totalChunks) / totalChunks;
  }

  String get chunkLabel {
    if (totalChunks <= 0) return '';
    return '$processedChunks/$totalChunks chunks';
  }

  String get etaLabel {
    final seconds = estimatedSecondsRemaining;
    if (seconds == null || seconds <= 0) return '';
    final minutes = (seconds / 60).ceil();
    return minutes <= 1 ? '<1 min left' : '~$minutes min left';
  }

  @override
  List<Object?> get props => [
        status,
        totalChunks,
        processedChunks,
        currentStep,
        estimatedSecondsRemaining,
        pdfSizeBytes,
      ];
}

class PaperSelectionState extends Equatable {
  final List<Paper> selectedPapers;
  final Map<String, String> paperStatuses;
  final Map<String, PaperIndexingProgress> paperProgress;
  final String? error;

  const PaperSelectionState({
    this.selectedPapers = const [],
    this.paperStatuses = const {},
    this.paperProgress = const {},
    this.error,
  });

  factory PaperSelectionState.initial() => const PaperSelectionState();

  PaperSelectionState copyWith({
    List<Paper>? selectedPapers,
    Map<String, String>? paperStatuses,
    Map<String, PaperIndexingProgress>? paperProgress,
    String? error,
  }) {
    return PaperSelectionState(
      selectedPapers: selectedPapers ?? this.selectedPapers,
      paperStatuses: paperStatuses ?? this.paperStatuses,
      paperProgress: paperProgress ?? this.paperProgress,
      error: error,
    );
  }

  bool get canAddMore => selectedPapers.length < 3;
  bool get hasProcessingPapers =>
      paperStatuses.values.any((status) => status == 'processing');
  bool get allPapersReady =>
      selectedPapers.isNotEmpty &&
      selectedPapers
          .every((paper) => paperStatuses[paper.arxivId] == 'completed');

  bool isSelected(String arxivId) =>
      selectedPapers.any((p) => p.arxivId == arxivId);

  String statusFor(String arxivId) => paperStatuses[arxivId] ?? 'idle';

  PaperIndexingProgress? progressFor(String arxivId) => paperProgress[arxivId];

  bool isReady(String arxivId) => statusFor(arxivId) == 'completed';

  Map<String, String> get paperTitles =>
      {for (final p in selectedPapers) p.arxivId: p.title};

  @override
  List<Object?> get props =>
      [selectedPapers, paperStatuses, paperProgress, error];
}
