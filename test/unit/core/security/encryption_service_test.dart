import 'package:flutter_test/flutter_test.dart';
import 'package:toga_assessment/core/errors/exceptions.dart';
import 'package:toga_assessment/core/security/encryption_service.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';

class InMemorySecureStorage implements ISecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> deleteAll() async => _data.clear();

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}

void main() {
  late ISecureStorage storage;
  late AesGcmEncryptionService encryptionService;

  setUp(() {
    storage = InMemorySecureStorage();
    encryptionService = AesGcmEncryptionService(secureStorage: storage);
  });

  group('AesGcmEncryptionService', () {
    test('generates and persists 256-bit encryption key', () async {
      final key = await encryptionService.getOrCreateKey();
      expect(key, isNotEmpty);
      expect(key.length, 32); // 256 bits = 32 bytes

      // Key should now exist in secure storage
      final storedKey = await storage.read('data_encryption_key');
      expect(storedKey, isNotNull);

      // Subsequent call retrieves the same key
      final secondKey = await encryptionService.getOrCreateKey();
      expect(secondKey, equals(key));
    });

    test('encrypts and decrypts string correctly (round-trip)', () async {
      const plainText = '{"lessonId":"L01","learnerProgress":100}';
      final cipherText = await encryptionService.encrypt(plainText);

      expect(cipherText, isNotEmpty);
      expect(cipherText, isNot(equals(plainText)));

      final decrypted = await encryptionService.decrypt(cipherText);
      expect(decrypted, equals(plainText));
    });

    test(
      'produces different ciphertexts for the same plaintext (unique nonces)',
      () async {
        const plainText = 'confidential draft response';
        final cipherText1 = await encryptionService.encrypt(plainText);
        final cipherText2 = await encryptionService.encrypt(plainText);

        expect(cipherText1, isNot(equals(cipherText2)));

        expect(await encryptionService.decrypt(cipherText1), equals(plainText));
        expect(await encryptionService.decrypt(cipherText2), equals(plainText));
      },
    );

    test('throws SecurityException when ciphertext is tampered', () async {
      const plainText = 'secure payload';
      final cipherText = await encryptionService.encrypt(plainText);

      // Alter bytes
      final tampered = '${cipherText.substring(0, cipherText.length - 2)}AA';

      expect(
        () => encryptionService.decrypt(tampered),
        throwsA(isA<SecurityException>()),
      );
    });
  });
}
