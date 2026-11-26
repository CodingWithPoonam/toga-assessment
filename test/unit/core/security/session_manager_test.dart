import 'package:flutter_test/flutter_test.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';
import 'package:toga_assessment/core/security/session_manager.dart';

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
  late SessionManager sessionManager;

  setUp(() {
    secureStorage = InMemorySecureStorage();
    sessionManager = SessionManager(secureStorage: secureStorage);
  });

  group('SessionManager Security & Lifecycle', () {
    test(
      'access token is held in memory and refresh credential in secure storage',
      () async {
        await sessionManager.setSession(
          learnerId: 'learner-a',
          accessToken: 'mem_token_123',
          refreshToken: 'sec_refresh_123',
        );

        // Access token available in memory
        expect(sessionManager.accessToken, equals('mem_token_123'));
        expect(sessionManager.activeLearnerId, equals('learner-a'));

        // Refresh token stored through ISecureStorage
        final storedRefresh = await sessionManager.getRefreshToken();
        expect(storedRefresh, equals('sec_refresh_123'));
      },
    );

    test('logout clears credentials from memory and secure storage', () async {
      await sessionManager.setSession(
        learnerId: 'learner-a',
        accessToken: 'mem_token_123',
        refreshToken: 'sec_refresh_123',
      );

      await sessionManager.clearAll();

      expect(sessionManager.accessToken, isNull);
      expect(sessionManager.activeLearnerId, isNull);
      expect(await sessionManager.getRefreshToken(), isNull);
      expect(await sessionManager.getPersistedLearnerId(), isNull);
    });

    test(
      'switching learner invalidates old session and increments generation',
      () async {
        await sessionManager.setSession(
          learnerId: 'learner-a',
          accessToken: 'token_a',
          refreshToken: 'refresh_a',
        );
        final initialGen = sessionManager.sessionGeneration;

        await sessionManager.invalidateSession();

        expect(sessionManager.sessionGeneration, greaterThan(initialGen));
        expect(sessionManager.accessToken, isNull);
        expect(sessionManager.isGenerationValid(initialGen), isFalse);
      },
    );

    test('late response with stale generation is rejected', () async {
      final genBefore = sessionManager.sessionGeneration;

      // Invalidate simulates user logging out or switching before network returns
      await sessionManager.invalidateSession();

      expect(sessionManager.isGenerationValid(genBefore), isFalse);
    });
  });
}
