import 'package:dio/dio.dart';
import '../../../core/network/api_exceptions.dart';

class BackendApiService {
  final Dio _dio;
  BackendApiService(this._dio);

  Future<Map<String, dynamic>> chatQuery({
    required String question,
    required List<String> paperIds,
    required Map<String, String> paperTitles,
    String? sessionId,
    String? expertiseLevel,
  }) async {
    return _post('/api/chat/query', {
      'question': question,
      'paper_ids': paperIds,
      'paper_titles': paperTitles,
      if (sessionId != null) 'session_id': sessionId,
      if (expertiseLevel != null) 'expertise_level': expertiseLevel,
    });
  }

  Future<Map<String, dynamic>> executeCommand({
    required String command,
    required List<String> paperIds,
    required Map<String, String> paperTitles,
    String? argument,
    String? sessionId,
  }) async {
    return _post('/api/chat/command', {
      'command': command,
      'paper_ids': paperIds,
      'paper_titles': paperTitles,
      if (argument != null) 'args': argument,
      if (sessionId != null) 'session_id': sessionId,
    });
  }

  Future<Map<String, dynamic>> processPaper({
    required String paperId,
    required String title,
    required List<String> authors,
    required String pdfUrl,
  }) async {
    return _post('/api/papers/process', {
      'paper_id': paperId,
      'title': title,
      'authors': authors,
      'pdf_url': pdfUrl,
    });
  }

  Future<Map<String, dynamic>> getPaperStatus(String paperId) async {
    return _get('/api/papers/$paperId/status');
  }

  Future<Map<String, dynamic>> generateSummary({
    required String paperId,
    required String content,
    required String level,
  }) async {
    return _post('/api/summary/generate', {
      'paper_id': paperId,
      'content': content,
      'level': level,
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> data) async {
    try {
      final r = await _dio.post(path, data: data);
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final r = await _dio.get(path);
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  Never _handleDioError(DioException e) {
    if (e.response?.statusCode == 404) throw ServerException('Not found', statusCode: 404);
    if (e.response?.statusCode == 422) throw ServerException('Validation error', statusCode: 422);
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw const TimeoutException();
    }
    if (e.type == DioExceptionType.connectionError) throw const NetworkException();
    throw ServerException(e.message ?? 'Server error', statusCode: e.response?.statusCode);
  }
}
