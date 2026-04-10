import 'package:equatable/equatable.dart';
import '../../../domain/entities/paper.dart';

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final List<Paper> papers;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final int totalResults;
  final bool isCached;

  const SearchLoaded({
    required this.papers,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
    this.totalResults = 0,
    this.isCached = false,
  });

  SearchLoaded copyWith({
    List<Paper>? papers,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SearchLoaded(
      papers: papers ?? this.papers,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      totalResults: totalResults,
      isCached: isCached,
    );
  }

  @override
  List<Object?> get props => [papers, currentPage, hasMore, isLoadingMore, isCached];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object?> get props => [message];
}
