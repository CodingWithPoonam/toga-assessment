import 'package:equatable/equatable.dart';
import 'learner.dart';

enum SessionStatus { active, expired, loggedOut }

/// Represents the active authenticated session
/// Access and refresh tokens are strictly omitted from UI models to prevent leakage
class AuthSession extends Equatable {
  final String learnerId;
  final Learner learner;
  final SessionStatus status;
  final DateTime expiresAt;
  final DateTime offlineLeaseExpiresAt;
  final int sessionGeneration;

  const AuthSession({
    required this.learnerId,
    required this.learner,
    required this.expiresAt,
    required this.offlineLeaseExpiresAt,
    this.status = SessionStatus.active,
    this.sessionGeneration = 1,
  });

  bool isExpired(DateTime now) => now.isAfter(expiresAt);

  bool isOfflineLeaseExpired(DateTime now) =>
      now.isAfter(offlineLeaseExpiresAt);

  AuthSession copyWith({
    String? learnerId,
    Learner? learner,
    SessionStatus? status,
    DateTime? expiresAt,
    DateTime? offlineLeaseExpiresAt,
    int? sessionGeneration,
  }) {
    return AuthSession(
      learnerId: learnerId ?? this.learnerId,
      learner: learner ?? this.learner,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      offlineLeaseExpiresAt:
          offlineLeaseExpiresAt ?? this.offlineLeaseExpiresAt,
      sessionGeneration: sessionGeneration ?? this.sessionGeneration,
    );
  }

  @override
  List<Object?> get props => [
    learnerId,
    learner,
    status,
    expiresAt,
    offlineLeaseExpiresAt,
    sessionGeneration,
  ];

  @override
  String toString() =>
      'AuthSession(learnerId: $learnerId, status: $status, expiresAt: $expiresAt, leaseExpiresAt: $offlineLeaseExpiresAt, gen: $sessionGeneration)';
}
