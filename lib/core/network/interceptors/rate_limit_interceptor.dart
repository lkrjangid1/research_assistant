import 'package:dio/dio.dart';

/// Enforces arXiv's 1-request-per-3-second rate limit.
/// Also implements exponential backoff on 503 responses.
class RateLimitInterceptor extends Interceptor {
  DateTime? _lastRequestTime;
  static const _minInterval = Duration(seconds: 3);
  static const _maxRetries = 3;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minInterval) {
        await Future.delayed(_minInterval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 503) {
      final retries = (err.requestOptions.extra['retries'] as int?) ?? 0;
      if (retries < _maxRetries) {
        final delay = Duration(seconds: 3 * (1 << retries)); // 3, 6, 12 seconds
        await Future.delayed(delay);
        err.requestOptions.extra['retries'] = retries + 1;
        try {
          final dio = Dio();
          final response = await dio.fetch(err.requestOptions);
          handler.resolve(response);
          return;
        } catch (_) {}
      }
    }
    handler.next(err);
  }
}
