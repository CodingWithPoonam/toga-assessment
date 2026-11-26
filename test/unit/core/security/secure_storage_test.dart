import 'package:flutter_test/flutter_test.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';

class FakeSecureStorage implements ISecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<void> deleteAll() async => _store.clear();

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async => _store[key] = value;
}

void main() {
  late ISecureStorage secureStorage;

  setUp(() {
    secureStorage = FakeSecureStorage();
  });

  group('ISecureStorage contract', () {
    test('writes and reads key-value pairs', () async {
      await secureStorage.write('refresh_token', 'sample_refresh_token_xyz');
      final value = await secureStorage.read('refresh_token');

      expect(value, equals('sample_refresh_token_xyz'));
      expect(await secureStorage.containsKey('refresh_token'), isTrue);
    });

    test('returns null for non-existent key', () async {
      final value = await secureStorage.read('missing_key');
      expect(value, isNull);
      expect(await secureStorage.containsKey('missing_key'), isFalse);
    });

    test('deletes individual keys', () async {
      await secureStorage.write('key1', 'val1');
      await secureStorage.delete('key1');

      expect(await secureStorage.read('key1'), isNull);
    });

    test('deleteAll removes all stored keys', () async {
      await secureStorage.write('k1', 'v1');
      await secureStorage.write('k2', 'v2');
      await secureStorage.deleteAll();

      expect(await secureStorage.read('k1'), isNull);
      expect(await secureStorage.read('k2'), isNull);
    });
  });
}
