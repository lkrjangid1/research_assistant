import 'package:dartz/dartz.dart';
import '../repositories/paper_repository.dart';
import '../../core/network/api_exceptions.dart';

class GetPaperSummary {
  final PaperRepository repository;
  GetPaperSummary(this.repository);

  Future<Either<Failure, String>> call({
    required String paperId,
    required String content,
    required String level,
  }) {
    return repository.getSummary(paperId: paperId, content: content, level: level);
  }
}
