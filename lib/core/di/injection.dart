import 'package:get_it/get_it.dart';
import '../database/app_database.dart';
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../network/network_config.dart';
import '../security/encryption_service.dart';
import '../security/secure_storage.dart';

final GetIt getIt = GetIt.instance;

/// Central dependency injection registration
/// Dependencies are initialized in strict dependency order:
/// 1. Security and local persistence
/// 2. Networking and interceptors
/// 3. Repositories and domain use cases (future phases)
/// 4. Presentation BLoCs (future phases)
Future<void> configureDependencies({
  NetworkConfig? networkConfig,
  ISecureStorage? secureStorageOverride,
  AppDatabase? databaseOverride,
}) async {
  // Reset existing registrations for test environments
  if (getIt.isRegistered<NetworkConfig>()) {
    await getIt.reset();
  }

  // 1. Network configuration
  getIt.registerSingleton<NetworkConfig>(
    networkConfig ?? NetworkConfig.development(),
  );

  // 2. Security Foundation
  final secureStorage = secureStorageOverride ?? AppSecureStorage();
  getIt.registerSingleton<ISecureStorage>(secureStorage);

  getIt.registerLazySingleton<IEncryptionService>(
    () => AesGcmEncryptionService(secureStorage: getIt<ISecureStorage>()),
  );

  // 3. Database Foundation
  final database = databaseOverride ?? AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // 4. Network Foundation
  // In-memory token provider for AuthInterceptor (Phase 2 hooks)
  getIt.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      accessTokenProvider: () => null, // Memory token holder in Phase 2
    ),
  );

  getIt.registerLazySingleton<DioClient>(
    () => DioClient(
      config: getIt<NetworkConfig>(),
      authInterceptor: getIt<AuthInterceptor>(),
    ),
  );

  // Ready signal for async registrations if needed
  await getIt.allReady();
}
