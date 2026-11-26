/// Global constants for the application
abstract class AppConstants {
  static const String appName = 'AIRMAN TOGA';

  // Network defaults (milliseconds)
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
  static const int sendTimeoutMs = 15000;

  // Secure storage keys
  static const String refreshTokenKey = 'auth_refresh_token';
  static const String encryptionKeyAlias = 'data_encryption_key';
  static const String activeLearnerIdKey = 'active_learner_id';
}
