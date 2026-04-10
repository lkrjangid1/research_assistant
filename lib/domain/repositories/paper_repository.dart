import 'package:dartz/dartz.dart';
import '../entities/paper.dart';
import '../../core/network/api_exceptions.dart';

abstract class PaperRepository {
  Future<Either<Failure, List<Paper>>> searchPapers({
    required String query,
    required int start,
    required int maxResults,
    String? sortBy,
    String? sortOrder,
  });

  Future<Either<Failure, String>> processPaper({
    required String arxivId,
    required String title,
    required List<String> authors,
    required String pdfUrl,
  });

  Future<Either<Failure, Map<String, dynamic>>> getPaperStatus(String paperId);

  Future<Either<Failure, String>> getSummary({
    required String paperId,
    required String content,
    required String level,
  });
}
