import 'package:dartz/dartz.dart';
import '../entities/paper.dart';
import '../repositories/paper_repository.dart';
import '../../core/network/api_exceptions.dart';

class SearchPapers {
  final PaperRepository repository;
  SearchPapers(this.repository);

  Future<Either<Failure, List<Paper>>> call({
    required String query,
    required int start,
    required int maxResults,
    String? sortBy,
    String? sortOrder,
  }) {
    return repository.searchPapers(
      query: query,
      start: start,
      maxResults: maxResults,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }
}
