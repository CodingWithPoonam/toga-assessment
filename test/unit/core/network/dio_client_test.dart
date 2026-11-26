import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toga_assessment/core/network/api_exceptions.dart';
import 'package:toga_assessment/core/network/auth_interceptor.dart';
import 'package:toga_assessment/core/network/dio_client.dart';
import 'package:toga_assessment/core/network/network_config.dart';

void main() {
  group('NetworkConfig', () {
    test('creates development config with appropriate defaults', () {
      final config = NetworkConfig.development();
      expect(config.isProduction, isFalse);
      expect(config.baseUrl, contains('dev'));
    });

    test('creates production config', () {
      final config = NetworkConfig.production();
      expect(config.isProduction, isTrue);
      expect(config.baseUrl, isNotEmpty);
    });
  });

  group('AuthInterceptor', () {
    test('injects Authorization header when token is present', () {
      final interceptor = AuthInterceptor(
        accessTokenProvider: () => 'valid_access_token_123',
      );

      final options = RequestOptions(path: '/test');
      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers['Authorization'], 'Bearer valid_access_token_123');
      expect(options.headers['Accept'], 'application/json');
    });

    test('omits Authorization header when token is null', () {
      final interceptor = AuthInterceptor(accessTokenProvider: () => null);

      final options = RequestOptions(path: '/test');
      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers['Authorization'], isNull);
      expect(options.headers['Accept'], 'application/json');
    });
  });

  group('ApiException mapping', () {
    test('maps 400 to BadRequestException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 400,
          data: {'message': 'Bad input'},
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = ApiException.fromDioException(dioError);
      expect(exception, isA<BadRequestException>());
      expect(exception.message, 'Bad input');
    });

    test('maps 401 to UnauthorizedException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
        type: DioExceptionType.badResponse,
      );

      final exception = ApiException.fromDioException(dioError);
      expect(exception, isA<UnauthorizedException>());
    });

    test('maps connection timeout to ApiTimeoutException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );

      final exception = ApiException.fromDioException(dioError);
      expect(exception, isA<ApiTimeoutException>());
    });

    test('maps connection error to NoInternetException', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );

      final exception = ApiException.fromDioException(dioError);
      expect(exception, isA<NoInternetException>());
    });
  });

  group('DioClient initialization', () {
    test('initializes with specified network configuration', () {
      final config = NetworkConfig.development();
      final client = DioClient(config: config);

      expect(client.dioInstance.options.baseUrl, config.baseUrl);
      expect(client.dioInstance.options.connectTimeout, config.connectTimeout);
      expect(client.dioInstance.options.responseType, ResponseType.json);
    });
  });
}
