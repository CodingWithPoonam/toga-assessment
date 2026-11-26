import 'package:equatable/equatable.dart';
import 'outbox_enums.dart';

/// Immutable domain entity representing a durable record in the SubmissionOutbox
class SubmissionRecord extends Equatable {
  final String id;
  final String learnerId;
  final String lessonId;
  final String revisionId;
  final String operationKey;
  final String encryptedPayload;
  final OutboxStatus status;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime? lastAttemptedAt;
  final DateTime? nextEligibleAttemptAt;
  final FailureCategory? lastFailureCategory;
  final DateTime? leaseExpiresAt;
  final String? serverAcknowledgement;

  const SubmissionRecord({
    required this.id,
    required this.learnerId,
    required this.lessonId,
    required this.revisionId,
    required this.operationKey,
    required this.encryptedPayload,
    required this.status,
    required this.attemptCount,
    required this.createdAt,
    this.lastAttemptedAt,
    this.nextEligibleAttemptAt,
    this.lastFailureCategory,
    this.leaseExpiresAt,
    this.serverAcknowledgement,
  });

  bool get isLeaseExpired =>
      leaseExpiresAt != null && DateTime.now().isAfter(leaseExpiresAt!);

  SubmissionRecord copyWith({
    String? id,
    String? learnerId,
    String? lessonId,
    String? revisionId,
    String? operationKey,
    String? encryptedPayload,
    OutboxStatus? status,
    int? attemptCount,
    DateTime? createdAt,
    DateTime? lastAttemptedAt,
    DateTime? nextEligibleAttemptAt,
    FailureCategory? lastFailureCategory,
    DateTime? leaseExpiresAt,
    String? serverAcknowledgement,
  }) {
    return SubmissionRecord(
      id: id ?? this.id,
      learnerId: learnerId ?? this.learnerId,
      lessonId: lessonId ?? this.lessonId,
      revisionId: revisionId ?? this.revisionId,
      operationKey: operationKey ?? this.operationKey,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptedAt: lastAttemptedAt ?? this.lastAttemptedAt,
      nextEligibleAttemptAt:
          nextEligibleAttemptAt ?? this.nextEligibleAttemptAt,
      lastFailureCategory: lastFailureCategory ?? this.lastFailureCategory,
      leaseExpiresAt: leaseExpiresAt ?? this.leaseExpiresAt,
      serverAcknowledgement:
          serverAcknowledgement ?? this.serverAcknowledgement,
    );
  }

  @override
  List<Object?> get props => [
    id,
    learnerId,
    lessonId,
    revisionId,
    operationKey,
    encryptedPayload,
    status,
    attemptCount,
    createdAt,
    lastAttemptedAt,
    nextEligibleAttemptAt,
    lastFailureCategory,
    leaseExpiresAt,
    serverAcknowledgement,
  ];
}
