import 'package:equatable/equatable.dart';
import '../../../domain/entities/paper.dart';

abstract class PaperDetailsState extends Equatable {
  const PaperDetailsState();
  @override
  List<Object?> get props => [];
}

class PaperDetailsInitial extends PaperDetailsState {
  const PaperDetailsInitial();
}

class PaperDetailsLoaded extends PaperDetailsState {
  final Paper paper;
  final String? summary;
  final List<String> keyPoints;
  final bool isLoadingSummary;
  final String expertiseLevel;

  const PaperDetailsLoaded({
    required this.paper,
    this.summary,
    this.keyPoints = const [],
    this.isLoadingSummary = false,
    this.expertiseLevel = 'intermediate',
  });

  PaperDetailsLoaded copyWith({
    String? summary,
    List<String>? keyPoints,
    bool? isLoadingSummary,
    String? expertiseLevel,
  }) {
    return PaperDetailsLoaded(
      paper: paper,
      summary: summary ?? this.summary,
      keyPoints: keyPoints ?? this.keyPoints,
      isLoadingSummary: isLoadingSummary ?? this.isLoadingSummary,
      expertiseLevel: expertiseLevel ?? this.expertiseLevel,
    );
  }

  @override
  List<Object?> get props => [paper, summary, keyPoints, isLoadingSummary, expertiseLevel];
}

class PaperDetailsError extends PaperDetailsState {
  final String message;
  const PaperDetailsError(this.message);
  @override
  List<Object?> get props => [message];
}
