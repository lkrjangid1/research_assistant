import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import 'paper_selection_state.dart';
import '../../../domain/entities/paper.dart';

class PaperSelectionCubit extends Cubit<PaperSelectionState> {
  PaperSelectionCubit() : super(PaperSelectionState.initial());

  void addPaper(Paper paper) {
    if (state.selectedPapers.length >= AppConstants.maxPapersPerSession) {
      emit(state.copyWith(error: 'Maximum ${AppConstants.maxPapersPerSession} papers allowed'));
      return;
    }
    if (state.selectedPapers.any((p) => p.arxivId == paper.arxivId)) return;
    emit(state.copyWith(selectedPapers: [...state.selectedPapers, paper], error: null));
  }

  void removePaper(String arxivId) {
    emit(state.copyWith(
      selectedPapers: state.selectedPapers.where((p) => p.arxivId != arxivId).toList(),
      error: null,
    ));
  }

  void clearAll() => emit(PaperSelectionState.initial());

  bool isSelected(String arxivId) => state.selectedPapers.any((p) => p.arxivId == arxivId);

  Map<String, String> get paperTitles =>
      {for (final p in state.selectedPapers) p.arxivId: p.title};
}
