/// Base application exception
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => '$runtimeType: $message (statusCode: $statusCode)';
}

class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

class CacheException extends AppException {
  const CacheException(super.message);
}

class SecurityException extends AppException {
  const SecurityException(super.message);
}
