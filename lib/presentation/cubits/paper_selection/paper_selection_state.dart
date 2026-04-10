import 'package:equatable/equatable.dart';
import '../../../domain/entities/paper.dart';

class PaperSelectionState extends Equatable {
  final List<Paper> selectedPapers;
  final Map<String, String> paperStatuses;
  final String? error;

  const PaperSelectionState({
    this.selectedPapers = const [],
    this.paperStatuses = const {},
    this.error,
  });

  factory PaperSelectionState.initial() => const PaperSelectionState();

  PaperSelectionState copyWith({
    List<Paper>? selectedPapers,
    Map<String, String>? paperStatuses,
    String? error,
  }) {
    return PaperSelectionState(
      selectedPapers: selectedPapers ?? this.selectedPapers,
      paperStatuses: paperStatuses ?? this.paperStatuses,
      error: error,
    );
  }

  bool get canAddMore => selectedPapers.length < 3;
  bool get hasProcessingPapers => paperStatuses.values.any((status) => status == 'processing');
  bool get allPapersReady =>
      selectedPapers.isNotEmpty &&
      selectedPapers.every((paper) => paperStatuses[paper.arxivId] == 'completed');

  bool isSelected(String arxivId) =>
      selectedPapers.any((p) => p.arxivId == arxivId);

  String statusFor(String arxivId) => paperStatuses[arxivId] ?? 'idle';

  bool isReady(String arxivId) => statusFor(arxivId) == 'completed';

  Map<String, String> get paperTitles =>
      {for (final p in selectedPapers) p.arxivId: p.title};

  @override
  List<Object?> get props => [selectedPapers, paperStatuses, error];
}
