import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../errors/exceptions.dart';
import '../utils/app_constants.dart';
import 'secure_storage.dart';

/// Contract for data encryption, decryption, and key lifecycle management
abstract class IEncryptionService {
  Future<String> encrypt({required String plainText, String? associatedData});

  Future<String> decrypt({required String cipherText, String? associatedData});
}

/// AES-GCM 256-bit authenticated encryption service
/// Stores key securely via ISecureStorage and generates a fresh nonce per encryption
class AesGcmEncryptionService implements IEncryptionService {
  final ISecureStorage secureStorage;
  final AesGcm _algorithm;
  SecretKey? _cachedKey;

  AesGcmEncryptionService({required this.secureStorage, AesGcm? algorithm})
    : _algorithm = algorithm ?? AesGcm.with256bits();

  Future<List<int>> getOrCreateKey() => _getOrCreateKey();

  Future<List<int>> _getOrCreateKey() async {
    final existingKeyBase64 = await secureStorage.read(
      AppConstants.encryptionKeyAlias,
    );

    if (existingKeyBase64 != null && existingKeyBase64.isNotEmpty) {
      final keyBytes = base64Decode(existingKeyBase64);
      _cachedKey = SecretKey(keyBytes);
      return keyBytes;
    }

    final newSecretKey = await _algorithm.newSecretKey();
    final keyBytes = await newSecretKey.extractBytes();
    await secureStorage.write(
      AppConstants.encryptionKeyAlias,
      base64Encode(keyBytes),
    );
    _cachedKey = newSecretKey;
    return keyBytes;
  }

  Future<SecretKey> _getSecretKey() async {
    if (_cachedKey != null) return _cachedKey!;
    final keyBytes = await _getOrCreateKey();
    _cachedKey = SecretKey(keyBytes);
    return _cachedKey!;
  }

  @override
  Future<String> encrypt({
    required String plainText,
    String? associatedData,
  }) async {
    try {
      final secretKey = await _getSecretKey();
      final nonce = _algorithm.newNonce();
      final aadBytes = associatedData != null
          ? utf8.encode(associatedData)
          : const <int>[];
      final secretBox = await _algorithm.encrypt(
        utf8.encode(plainText),
        secretKey: secretKey,
        nonce: nonce,
        aad: aadBytes,
      );

      final packed = secretBox.concatenation(nonce: true, mac: true);
      return base64Encode(packed);
    } catch (e) {
      throw SecurityException('Failed to encrypt data: $e');
    }
  }

  @override
  Future<String> decrypt({
    required String cipherText,
    String? associatedData,
  }) async {
    try {
      final secretKey = await _getSecretKey();
      final packed = base64Decode(cipherText);

      final secretBox = SecretBox.fromConcatenation(
        packed,
        nonceLength: _algorithm.nonceLength,
        macLength: _algorithm.macAlgorithm.macLength,
      );

      final aadBytes = associatedData != null
          ? utf8.encode(associatedData)
          : const <int>[];
      final clearBytes = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
        aad: aadBytes,
      );

      return utf8.decode(clearBytes);
    } on SecretBoxAuthenticationError {
      throw const SecurityException(
        'Authentication tag mismatch - data corrupted or tampered',
      );
    } catch (e) {
      throw SecurityException('Failed to decrypt data: $e');
    }
  }
}
