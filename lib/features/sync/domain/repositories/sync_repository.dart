import '../entities/outbox_enums.dart';
import '../entities/submission_record.dart';

/// Contract for durable submission outbox persistence, atomic staging, and lease management
abstract class SyncRepository {
  /// Atomically stages an in-progress quiz draft into the SubmissionOutbox in one SQLite transaction
  Future<SubmissionRecord> stageSubmission({
    required String learnerId,
    required String lessonId,
  });

  /// Retrieves all submissions eligible for synchronization for the given learner
  Future<List<SubmissionRecord>> getPendingSubmissions(String learnerId);

  /// Atomically claims an outbox record into in_flight status with an active lease
  Future<SubmissionRecord?> claimSubmissionForSync({
    required String outboxId,
    required Duration leaseDuration,
  });

  /// Atomically commits server acknowledgement, completes outbox, and acknowledges draft
  Future<void> acknowledgeSubmission({
    required String outboxId,
    required String acknowledgementJson,
  });

  /// Updates outbox attempt count and schedules a transient retry
  Future<void> markSubmissionFailed({
    required String outboxId,
    required FailureCategory category,
    required DateTime? nextEligibleAttemptAt,
  });

  /// Permanently blocks a submission (e.g. stale revision) preserving snapshot and draft
  Future<void> blockSubmission({
    required String outboxId,
    required FailureCategory category,
  });

  /// Recovers any in_flight records whose lease has expired back to pending or retry_scheduled
  Future<int> recoverExpiredLeases();

  /// Retrieves outbox record by stable idempotency key
  Future<SubmissionRecord?> getOutboxByOperationKey(String operationKey);

  /// Retrieves outbox record for a given learner and lesson
  Future<SubmissionRecord?> getOutboxForLesson({
    required String learnerId,
    required String lessonId,
  });
}
