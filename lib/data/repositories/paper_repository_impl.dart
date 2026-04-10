import 'package:dartz/dartz.dart';
import '../../domain/entities/paper.dart';
import '../../domain/repositories/paper_repository.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/utils/xml_parser.dart';
import '../datasources/remote/arxiv_api_service.dart';
import '../datasources/remote/backend_api_service.dart';

class PaperRepositoryImpl implements PaperRepository {
  final ArxivApiService _arxivApi;
  final BackendApiService _backendApi;

  PaperRepositoryImpl(this._arxivApi, this._backendApi);

  @override
  Future<Either<Failure, List<Paper>>> searchPapers({
    required String query,
    required int start,
    required int maxResults,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final xml = await _arxivApi.searchPapers(
        query: query,
        start: start,
        maxResults: maxResults,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      final papers = ArxivXmlParser.parseSearchResponse(xml);
      return Right(papers);
    } on RateLimitException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on TimeoutException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ParsingFailure('Failed to parse search results: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> processPaper({
    required String arxivId,
    required String title,
    required List<String> authors,
    required String pdfUrl,
  }) async {
    try {
      final result = await _backendApi.processPaper(
        paperId: arxivId,
        title: title,
        authors: authors,
        pdfUrl: pdfUrl,
      );
      return Right(result['status'] as String);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to process paper: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPaperStatus(String paperId) async {
    try {
      final result = await _backendApi.getPaperStatus(paperId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get status: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> getSummary({
    required String paperId,
    required String content,
    required String level,
  }) async {
    try {
      final result = await _backendApi.generateSummary(
        paperId: paperId,
        content: content,
        level: level,
      );
      return Right(result['summary'] as String);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to generate summary: $e'));
    }
  }
}
