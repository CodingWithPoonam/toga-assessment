import '../../domain/entities/auth_session.dart';
import 'learner_model.dart';

/// Data transfer model for authentication responses containing tokens
class SessionModel {
  final String accessToken;
  final String refreshToken;
  final LearnerModel learner;
  final DateTime expiresAt;
  final DateTime offlineLeaseExpiresAt;

  const SessionModel({
    required this.accessToken,
    required this.refreshToken,
    required this.learner,
    required this.expiresAt,
    required this.offlineLeaseExpiresAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'] as String?;
    final refreshToken = json['refreshToken'] as String?;
    final learnerData = json['learner'] as Map<String, dynamic>?;
    final expiresAtStr = json['expiresAt'] as String?;
    final leaseExpiresAtStr = json['offlineLeaseExpiresAt'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw const FormatException(
        'Missing accessToken in authentication response',
      );
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const FormatException(
        'Missing refreshToken in authentication response',
      );
    }
    if (learnerData == null) {
      throw const FormatException(
        'Missing learner data in authentication response',
      );
    }

    final learner = LearnerModel.fromJson(learnerData);
    final expiresAt = expiresAtStr != null
        ? DateTime.parse(expiresAtStr)
        : DateTime.now().add(const Duration(hours: 1));
    final offlineLeaseExpiresAt = leaseExpiresAtStr != null
        ? DateTime.parse(leaseExpiresAtStr)
        : DateTime.now().add(const Duration(hours: 24));

    return SessionModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      learner: learner,
      expiresAt: expiresAt,
      offlineLeaseExpiresAt: offlineLeaseExpiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'learner': learner.toJson(),
    'expiresAt': expiresAt.toIso8601String(),
    'offlineLeaseExpiresAt': offlineLeaseExpiresAt.toIso8601String(),
  };

  AuthSession toEntity({int generation = 1}) {
    return AuthSession(
      learnerId: learner.id,
      learner: learner,
      expiresAt: expiresAt,
      offlineLeaseExpiresAt: offlineLeaseExpiresAt,
      sessionGeneration: generation,
      status: SessionStatus.active,
    );
  }
}
