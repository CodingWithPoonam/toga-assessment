import 'package:dio/dio.dart';
import '../errors/exceptions.dart';

/// Standardized API exception hierarchy mapped from Dio errors
class ApiException extends AppException {
  ApiException(super.message, {super.statusCode});

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiTimeoutException('Connection timed out');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message =
            _extractErrorMessage(error.response?.data) ??
            error.response?.statusMessage ??
            'Request failed with status $statusCode';

        if (statusCode == 400) return BadRequestException(message);
        if (statusCode == 401) return UnauthorizedException(message);
        if (statusCode == 403) return ForbiddenException(message);
        if (statusCode == 404) return NotFoundException(message);
        if (statusCode == 409) return ConflictException(message);
        if (statusCode != null && statusCode >= 500) {
          return InternalServerErrorException(message, statusCode: statusCode);
        }
        return ApiException(message, statusCode: statusCode);
      case DioExceptionType.connectionError:
        return NoInternetException('Unable to connect to the server');
      case DioExceptionType.cancel:
        return RequestCancelledException('Request was cancelled');
      case DioExceptionType.badCertificate:
        return BadCertificateException('Invalid TLS certificate');
      case DioExceptionType.unknown:
        return UnknownApiException(
          error.message ?? 'An unexpected error occurred',
        );
    }
  }

  static String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) return data['message'] as String;
      if (data['error'] is String) return data['error'] as String;
    }
    return null;
  }
}

class ApiTimeoutException extends ApiException {
  ApiTimeoutException(super.message);
}

class BadRequestException extends ApiException {
  BadRequestException(super.message) : super(statusCode: 400);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message) : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message) : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message) : super(statusCode: 404);
}

class ConflictException extends ApiException {
  ConflictException(super.message) : super(statusCode: 409);
}

class InternalServerErrorException extends ApiException {
  InternalServerErrorException(super.message, {super.statusCode = 500});
}

class NoInternetException extends ApiException {
  NoInternetException(super.message);
}

class RequestCancelledException extends ApiException {
  RequestCancelledException(super.message);
}

class BadCertificateException extends ApiException {
  BadCertificateException(super.message);
}

class UnknownApiException extends ApiException {
  UnknownApiException(super.message);
}
