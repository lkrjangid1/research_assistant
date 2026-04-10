abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => message;
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode});
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out']);
}

class RateLimitException extends AppException {
  const RateLimitException([super.message = 'Rate limit exceeded. Please wait and try again.']);
}

class ParsingException extends AppException {
  const ParsingException([super.message = 'Failed to parse response']);
}

// ── Failure types for Either<Failure, T> ─────────────────────────────────────

abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
