import '../utils/app_constants.dart';

/// Network environment configuration separating dev and prod setups
class NetworkConfig {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final bool isProduction;

  const NetworkConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(
      milliseconds: AppConstants.connectTimeoutMs,
    ),
    this.receiveTimeout = const Duration(
      milliseconds: AppConstants.receiveTimeoutMs,
    ),
    this.sendTimeout = const Duration(milliseconds: AppConstants.sendTimeoutMs),
    this.isProduction = false,
  });

  factory NetworkConfig.development({String? baseUrl}) {
    return NetworkConfig(
      baseUrl: baseUrl ?? 'https://dev-api.airman.ai',
      isProduction: false,
    );
  }

  factory NetworkConfig.production({String? baseUrl}) {
    return NetworkConfig(
      baseUrl: baseUrl ?? 'https://api.airman.ai',
      isProduction: true,
    );
  }
}
