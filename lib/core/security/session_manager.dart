import 'dart:async';
import 'secure_storage.dart';
import '../utils/app_constants.dart';

/// Contract for managing sensitive in-memory session tokens and lifecycle
abstract class ISessionManager {
  String? get accessToken;
  String? get activeLearnerId;
  int get sessionGeneration;

  /// Holds the access token in memory and persists refresh token securely
  Future<void> setSession({
    required String learnerId,
    required String accessToken,
    required String refreshToken,
  });

  /// Retrieves the persisted refresh token from secure storage
  Future<String?> getRefreshToken();

  /// Retrieves the persisted active learner ID from secure storage
  Future<String?> getPersistedLearnerId();

  /// Invalidates active in-memory session and increments session generation
  Future<void> invalidateSession();

  /// Completely clears in-memory tokens and secure refresh credentials
  Future<void> clearAll();

  /// Checks if an operation initiated with [generation] is still valid
  bool isGenerationValid(int generation);
}

/// Implementation of ISessionManager holding access token strictly in-memory
class SessionManager implements ISessionManager {
  final ISecureStorage secureStorage;
  String? _accessToken;
  String? _activeLearnerId;
  int _sessionGeneration = 0;

  SessionManager({required this.secureStorage});

  @override
  String? get accessToken => _accessToken;

  @override
  String? get activeLearnerId => _activeLearnerId;

  @override
  int get sessionGeneration => _sessionGeneration;

  @override
  Future<void> setSession({
    required String learnerId,
    required String accessToken,
    required String refreshToken,
  }) async {
    _sessionGeneration++;
    _accessToken = accessToken;
    _activeLearnerId = learnerId;

    await secureStorage.write(AppConstants.refreshTokenKey, refreshToken);
    await secureStorage.write(AppConstants.activeLearnerIdKey, learnerId);
  }

  @override
  Future<String?> getRefreshToken() async {
    return secureStorage.read(AppConstants.refreshTokenKey);
  }

  @override
  Future<String?> getPersistedLearnerId() async {
    return secureStorage.read(AppConstants.activeLearnerIdKey);
  }

  @override
  Future<void> invalidateSession() async {
    _sessionGeneration++;
    _accessToken = null;
  }

  @override
  Future<void> clearAll() async {
    _sessionGeneration++;
    _accessToken = null;
    _activeLearnerId = null;

    await secureStorage.delete(AppConstants.refreshTokenKey);
    await secureStorage.delete(AppConstants.activeLearnerIdKey);
  }

  @override
  bool isGenerationValid(int generation) => generation == _sessionGeneration;
}
