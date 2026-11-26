import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/lessons/data/datasources/lesson_fixture_datasource.dart';
import '../../features/lessons/data/datasources/lesson_local_datasource.dart';
import '../../features/lessons/data/repositories/lesson_repository_impl.dart';
import '../../features/lessons/domain/repositories/lesson_repository.dart';
import '../../features/lessons/presentation/bloc/lesson_bloc.dart';
import '../../features/quiz/data/datasources/quiz_fixture_datasource.dart';
import '../../features/quiz/data/datasources/quiz_local_datasource.dart';
import '../../features/quiz/data/repositories/quiz_repository_impl.dart';
import '../../features/quiz/domain/repositories/quiz_repository.dart';
import '../../features/quiz/presentation/bloc/quiz_bloc.dart';
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
  LessonRepository? lessonRepositoryOverride,
  QuizRepository? quizRepositoryOverride,
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

  // 6. Lessons Feature
  getIt.registerLazySingleton<LessonLocalDataSource>(
    () => LessonLocalDataSource(database: getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<LessonFixtureDataSource>(
    () => LessonFixtureDataSource(),
  );
  final lessonRepository =
      lessonRepositoryOverride ??
      LessonRepositoryImpl(
        localDataSource: getIt<LessonLocalDataSource>(),
        fixtureDataSource: getIt<LessonFixtureDataSource>(),
      );
  getIt.registerSingleton<LessonRepository>(lessonRepository);

  // 7. Quiz Feature
  getIt.registerLazySingleton<QuizLocalDataSource>(
    () => QuizLocalDataSource(
      database: getIt<AppDatabase>(),
      encryptionService: getIt<IEncryptionService>(),
    ),
  );
  getIt.registerLazySingleton<QuizFixtureDataSource>(
    () => QuizFixtureDataSource(),
  );
  final quizRepository =
      quizRepositoryOverride ??
      QuizRepositoryImpl(
        localDataSource: getIt<QuizLocalDataSource>(),
        fixtureDataSource: getIt<QuizFixtureDataSource>(),
        sessionManager: getIt<ISessionManager>(),
      );
  getIt.registerSingleton<QuizRepository>(quizRepository);

  // 8. Presentation BLoCs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerFactory<LessonBloc>(
    () => LessonBloc(lessonRepository: getIt<LessonRepository>()),
  );
  getIt.registerFactory<QuizBloc>(
    () => QuizBloc(
      quizRepository: getIt<QuizRepository>(),
      sessionManager: getIt<ISessionManager>(),
    ),
  );

  await getIt.allReady();
}
