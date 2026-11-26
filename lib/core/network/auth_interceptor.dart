import 'dart:async';
import 'package:dio/dio.dart';

/// Provider interface to fetch the in-memory access token
typedef AccessTokenProvider = String? Function();

/// Provider interface to execute shared token refresh
typedef TokenRefreshProvider = Future<String?> Function();

/// Interceptor for authentication headers and single-flight token refresh coordination
class AuthInterceptor extends Interceptor {
  final AccessTokenProvider? accessTokenProvider;
  final TokenRefreshProvider? tokenRefreshProvider;
  final Future<void> Function()? onSessionExpired;

  Completer<String?>? _refreshCompleter;

  AuthInterceptor({
    this.accessTokenProvider,
    this.tokenRefreshProvider,
    this.onSessionExpired,
  });

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
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Coordinate token refresh on 401 Unauthorized
    if (err.response?.statusCode == 401 && tokenRefreshProvider != null) {
      final isRetry = err.requestOptions.extra['is_retry'] == true;
      if (isRetry) {
        handler.next(err);
        return;
      }

      try {
        if (_refreshCompleter == null) {
          _refreshCompleter = Completer<String?>();
          try {
            final newToken = await tokenRefreshProvider!();
            _refreshCompleter!.complete(newToken);
          } catch (refreshErr) {
            _refreshCompleter!.completeError(refreshErr);
            onSessionExpired?.call();
          } finally {
            _refreshCompleter = null;
          }
        }

        final newToken = await _refreshCompleter!.future;
        if (newToken != null && newToken.isNotEmpty) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          options.extra['is_retry'] = true;

          final dio = Dio();
          final response = await dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (_) {
        // Refresh failed; proceed with 401 error
      }
    }

    handler.next(err);
  }
}
