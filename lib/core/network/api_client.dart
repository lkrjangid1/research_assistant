import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'interceptors/rate_limit_interceptor.dart';

Dio createBackendDio() {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.backendBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.add(LogInterceptor(responseBody: false));
  return dio;
}

Dio createArxivDio() {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.arxivBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));
  dio.interceptors.add(RateLimitInterceptor());
  dio.interceptors.add(LogInterceptor(responseBody: false));
  return dio;
}
