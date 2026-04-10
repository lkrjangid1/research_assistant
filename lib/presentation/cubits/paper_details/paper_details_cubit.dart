import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/paper.dart';
import '../../../domain/usecases/get_paper_summary.dart';
import 'paper_details_state.dart';

class PaperDetailsCubit extends Cubit<PaperDetailsState> {
  final GetPaperSummary _getSummary;

  PaperDetailsCubit(this._getSummary) : super(const PaperDetailsInitial());

  void loadPaper(Paper paper) {
    emit(PaperDetailsLoaded(paper: paper));
  }

  void setExpertiseLevel(String level) {
    final current = state;
    if (current is! PaperDetailsLoaded) return;
    emit(current.copyWith(expertiseLevel: level));
  }

  Future<void> generateSummary({String level = 'intermediate'}) async {
    final current = state;
    if (current is! PaperDetailsLoaded) return;
    emit(current.copyWith(isLoadingSummary: true, expertiseLevel: level));

    final result = await _getSummary(
      paperId: current.paper.arxivId,
      content: current.paper.abstract,
      level: level,
    );

    result.fold(
      (failure) => emit(current.copyWith(isLoadingSummary: false)),
      (summary) => emit(current.copyWith(summary: summary, isLoadingSummary: false)),
    );
  }
}
