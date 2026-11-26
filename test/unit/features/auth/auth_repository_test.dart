import 'package:flutter_test/flutter_test.dart';
import 'package:toga_assessment/core/errors/failures.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';
import 'package:toga_assessment/core/security/session_manager.dart';
import 'package:toga_assessment/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:toga_assessment/features/auth/data/repositories/auth_repository_impl.dart';

class InMemorySecureStorage implements ISecureStorage {
  final Map<String, String> _map = {};

  @override
  Future<bool> containsKey(String key) async => _map.containsKey(key);

  @override
  Future<void> delete(String key) async => _map.remove(key);

  @override
  Future<void> deleteAll() async => _map.clear();

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;
}

void main() {
  late ISecureStorage secureStorage;
  late ISessionManager sessionManager;
  late AuthRemoteDataSource remoteDataSource;
  late DateTime fixedNow;
  late AuthRepositoryImpl repository;

  setUp(() {
    fixedNow = DateTime(2026, 11, 26, 12, 0, 0);
    secureStorage = InMemorySecureStorage();
    sessionManager = SessionManager(secureStorage: secureStorage);
    remoteDataSource = MockAuthRemoteDataSource(
      networkLatency: Duration.zero,
      clock: () => fixedNow,
    );
    repository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      sessionManager: sessionManager,
      clock: () => fixedNow,
    );
  });

  group('AuthRepositoryImpl', () {
    test(
      '1. Successful learner A login returns valid session and stores tokens',
      () async {
        final session = await repository.login(
          learnerId: SyntheticLearners.learnerA.id,
          password: SyntheticLearners.validPassword,
        );

        expect(session.learnerId, equals(SyntheticLearners.learnerA.id));
        expect(session.learner.displayName, contains('Alex Mercer'));
        expect(sessionManager.accessToken, isNotNull);
        expect(
          await sessionManager.getRefreshToken(),
          contains('synthetic_refresh_token_learner-a'),
        );
      },
    );

    test('2. Successful learner B login returns valid session', () async {
      final session = await repository.login(
        learnerId: SyntheticLearners.learnerB.id,
        password: SyntheticLearners.validPassword,
      );

      expect(session.learnerId, equals(SyntheticLearners.learnerB.id));
      expect(session.learner.displayName, contains('Blake Vance'));
    });

    test('3. Invalid credentials throws ServerFailure', () async {
      expect(
        () => repository.login(
          learnerId: SyntheticLearners.learnerA.id,
          password: 'wrong_password',
        ),
        throwsA(isA<ServerFailure>()),
      );
    });

    test(
      '4. Session restoration restores session using stored refresh token',
      () async {
        await repository.login(
          learnerId: SyntheticLearners.learnerA.id,
          password: SyntheticLearners.validPassword,
        );

        // Invalidate in-memory access token to simulate app relaunch
        await sessionManager.invalidateSession();
        expect(sessionManager.accessToken, isNull);

        final restored = await repository.restoreSession();
        expect(restored, isNotNull);
        expect(restored!.learnerId, equals(SyntheticLearners.learnerA.id));
        expect(sessionManager.accessToken, isNotNull);
      },
    );

    test(
      '7. Logout clears credentials from repository and session manager',
      () async {
        await repository.login(
          learnerId: SyntheticLearners.learnerA.id,
          password: SyntheticLearners.validPassword,
        );

        await repository.logout();

        expect(sessionManager.accessToken, isNull);
        expect(await sessionManager.getRefreshToken(), isNull);
      },
    );

    test(
      '8. Switching learner switches active learner and updates tokens',
      () async {
        await repository.login(
          learnerId: SyntheticLearners.learnerA.id,
          password: SyntheticLearners.validPassword,
        );

        final newSession = await repository.switchLearner(
          targetLearnerId: SyntheticLearners.learnerB.id,
          password: SyntheticLearners.validPassword,
        );

        expect(newSession.learnerId, equals(SyntheticLearners.learnerB.id));
        expect(
          sessionManager.activeLearnerId,
          equals(SyntheticLearners.learnerB.id),
        );
        expect(await sessionManager.getRefreshToken(), contains('learner-b'));
      },
    );

    test(
      '12. Failed session restoration does not crash or corrupt state',
      () async {
        // Simulate broken or invalid refresh token in storage
        await secureStorage.write('auth_refresh_token', 'corrupted_token');
        await secureStorage.write('active_learner_id', 'learner-a');

        final restored = await repository.restoreSession();
        expect(restored, isNull);
        expect(sessionManager.accessToken, isNull);
      },
    );

    test('13. Offline lease is valid within 24 hours', () async {
      final session = await repository.login(
        learnerId: SyntheticLearners.learnerA.id,
        password: SyntheticLearners.validPassword,
      );

      // 23 hours later: lease must still be valid
      repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        sessionManager: sessionManager,
        clock: () => fixedNow.add(const Duration(hours: 23)),
      );

      expect(repository.validateOfflineAccess(session), isTrue);
    });

    test('14. Offline lease is invalid after 24 hours', () async {
      final session = await repository.login(
        learnerId: SyntheticLearners.learnerA.id,
        password: SyntheticLearners.validPassword,
      );

      // 25 hours later: lease must expire
      repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        sessionManager: sessionManager,
        clock: () => fixedNow.add(const Duration(hours: 25)),
      );

      expect(repository.validateOfflineAccess(session), isFalse);
    });

    test(
      '15. Concurrent authentication operation during login throws SecurityException',
      () async {
        final delayedRemoteSource = MockAuthRemoteDataSource(
          networkLatency: const Duration(milliseconds: 50),
          clock: () => fixedNow,
        );
        final repo = AuthRepositoryImpl(
          remoteDataSource: delayedRemoteSource,
          sessionManager: sessionManager,
          clock: () => fixedNow,
        );

        final future = repo.login(
          learnerId: SyntheticLearners.learnerA.id,
          password: SyntheticLearners.validPassword,
        );

        // Invalidate session generation before future completes
        await sessionManager.invalidateSession();

        expect(future, throwsA(isA<ServerFailure>()));
      },
    );
  });
}
