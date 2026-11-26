import '../entities/auth_session.dart';

/// Contract for authentication operations
abstract class AuthRepository {
  /// Authenticates a learner using credentials
  Future<AuthSession> login({
    required String learnerId,
    required String password,
  });

  /// Restores session using stored refresh credential
  Future<AuthSession?> restoreSession();

  /// Terminates active session and clears session tokens
  Future<void> logout();

  /// Switches active learner safely, invalidating previous session
  Future<AuthSession> switchLearner({
    required String targetLearnerId,
    required String password,
  });

  /// Refreshes access token using stored refresh credential
  Future<AuthSession> refreshSession();

  /// Validates whether the offline lease is currently active
  bool validateOfflineAccess(AuthSession session);
}
