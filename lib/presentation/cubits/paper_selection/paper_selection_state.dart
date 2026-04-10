import 'package:equatable/equatable.dart';
import '../../../domain/entities/paper.dart';

class PaperSelectionState extends Equatable {
  final List<Paper> selectedPapers;
  final String? error;

  const PaperSelectionState({this.selectedPapers = const [], this.error});

  factory PaperSelectionState.initial() => const PaperSelectionState();

  PaperSelectionState copyWith({List<Paper>? selectedPapers, String? error}) {
    return PaperSelectionState(
      selectedPapers: selectedPapers ?? this.selectedPapers,
      error: error,
    );
  }

  bool get canAddMore => selectedPapers.length < 3;

  bool isSelected(String arxivId) =>
      selectedPapers.any((p) => p.arxivId == arxivId);

  Map<String, String> get paperTitles =>
      {for (final p in selectedPapers) p.arxivId: p.title};

  @override
  List<Object?> get props => [selectedPapers, error];
}
