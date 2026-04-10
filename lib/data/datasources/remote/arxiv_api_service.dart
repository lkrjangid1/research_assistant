import 'package:dio/dio.dart';
import '../../../core/network/api_exceptions.dart';

class ArxivApiService {
  final Dio _dio;
  ArxivApiService(this._dio);

  Future<String> searchPapers({
    required String query,
    required int start,
    required int maxResults,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final response = await _dio.get('', queryParameters: {
        'search_query': query,
        'start': start,
        'max_results': maxResults,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
      });
      return response.data as String;
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) throw const RateLimitException();
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const TimeoutException();
      }
      throw NetworkException(e.message ?? 'Network error');
    }
  }
}
