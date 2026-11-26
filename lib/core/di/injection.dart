import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../database/app_database.dart';
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../network/network_config.dart';
import '../security/encryption_service.dart';
import '../security/secure_storage.dart';
import '../security/session_manager.dart';

final GetIt getIt = GetIt.instance;

/// Central dependency injection registration
Future<void> configureDependencies({
  NetworkConfig? networkConfig,
  ISecureStorage? secureStorageOverride,
  AppDatabase? databaseOverride,
  ISessionManager? sessionManagerOverride,
  AuthRemoteDataSource? remoteDataSourceOverride,
  AuthRepository? authRepositoryOverride,
}) async {
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

  final sessionManager =
      sessionManagerOverride ??
      SessionManager(secureStorage: getIt<ISecureStorage>());
  getIt.registerSingleton<ISessionManager>(sessionManager);

  // 3. Database Foundation
  final database = databaseOverride ?? AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  // 4. Network Foundation
  // Token provider fetches memory-held access token from SessionManager
  getIt.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(
      accessTokenProvider: () => getIt<ISessionManager>().accessToken,
    ),
  );

  getIt.registerLazySingleton<DioClient>(
    () => DioClient(
      config: getIt<NetworkConfig>(),
      authInterceptor: getIt<AuthInterceptor>(),
    ),
  );

  // 5. Auth Data & Domain
  final remoteDataSource =
      remoteDataSourceOverride ?? MockAuthRemoteDataSource();
  getIt.registerSingleton<AuthRemoteDataSource>(remoteDataSource);

  final authRepository =
      authRepositoryOverride ??
      AuthRepositoryImpl(
        remoteDataSource: getIt<AuthRemoteDataSource>(),
        sessionManager: getIt<ISessionManager>(),
      );
  getIt.registerSingleton<AuthRepository>(authRepository);

  // 6. Presentation BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );

  await getIt.allReady();
}
