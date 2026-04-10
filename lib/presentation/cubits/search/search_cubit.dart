import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/search_papers.dart';
import '../../../core/constants/app_constants.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchPapers _searchPapers;

  String _lastQuery = '';
  int _currentPage = 0;

  SearchCubit(this._searchPapers) : super(const SearchInitial());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    emit(const SearchLoading());
    _lastQuery = query;
    _currentPage = 0;

    final result = await _searchPapers(
      query: query,
      start: 0,
      maxResults: AppConstants.searchPageSize,
    );

    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (papers) => emit(SearchLoaded(
        papers: papers,
        currentPage: 0,
        hasMore: papers.length == AppConstants.searchPageSize,
      )),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! SearchLoaded || current.isLoadingMore || !current.hasMore) return;

    emit(current.copyWith(isLoadingMore: true));
    _currentPage++;
    final start = _currentPage * AppConstants.searchPageSize;

    final result = await _searchPapers(
      query: _lastQuery,
      start: start,
      maxResults: AppConstants.searchPageSize,
    );

    result.fold(
      (failure) => emit(current.copyWith(isLoadingMore: false)),
      (newPapers) => emit(current.copyWith(
        papers: [...current.papers, ...newPapers],
        currentPage: _currentPage,
        hasMore: newPapers.length == AppConstants.searchPageSize,
        isLoadingMore: false,
      )),
    );
  }

  Future<void> retry() async {
    if (_lastQuery.isNotEmpty) await search(_lastQuery);
  }

  void reset() {
    _lastQuery = '';
    _currentPage = 0;
    emit(const SearchInitial());
  }
}
