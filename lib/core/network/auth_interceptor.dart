import 'package:dio/dio.dart';

/// Provider interface to fetch the in-memory access token
typedef AccessTokenProvider = String? Function();

/// Foundation interceptor for authentication headers
/// Token refresh will be implemented in Phase 2
class AuthInterceptor extends Interceptor {
  final AccessTokenProvider? accessTokenProvider;

  AuthInterceptor({this.accessTokenProvider});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Standard JSON headers
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';

    // Inject in-memory access token if available
    final token = accessTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Hook for future 401 refresh handling (Phase 2)
    handler.next(err);
  }
}
