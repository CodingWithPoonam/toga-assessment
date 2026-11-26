import '../../../../core/errors/exceptions.dart';
import '../../../../core/security/session_manager.dart';
import '../../domain/entities/outbox_enums.dart';
import '../../domain/entities/submission_record.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_local_datasource.dart';

/// Implementation of SyncRepository coordinating outbox persistence and session security
class SyncRepositoryImpl implements SyncRepository {
  final SyncLocalDataSource localDataSource;
  final ISessionManager sessionManager;

  SyncRepositoryImpl({
    required this.localDataSource,
    required this.sessionManager,
  });

  void _validateLearnerSession(String learnerId) {
    final activeLearnerId = sessionManager.activeLearnerId;
    if (activeLearnerId == null || activeLearnerId.isEmpty) {
      throw const SecurityException(
        'Unverified learner session: activeLearnerId is null',
      );
    }
    if (activeLearnerId != learnerId) {
      throw SecurityException(
        'Tenant boundary violation: requested learnerId ($learnerId) does not match active session ($activeLearnerId)',
      );
    }
  }

  @override
  Future<SubmissionRecord> stageSubmission({
    required String learnerId,
    required String lessonId,
  }) async {
    _validateLearnerSession(learnerId);
    return localDataSource.stageSubmissionAtomically(
      learnerId: learnerId,
      lessonId: lessonId,
    );
  }

  @override
  Future<List<SubmissionRecord>> getPendingSubmissions(String learnerId) async {
    _validateLearnerSession(learnerId);
    return localDataSource.getPendingSubmissions(learnerId);
  }

  @override
  Future<SubmissionRecord?> claimSubmissionForSync({
    required String outboxId,
    required Duration leaseDuration,
  }) {
    return localDataSource.claimSubmissionForSync(
      outboxId: outboxId,
      leaseDuration: leaseDuration,
    );
  }

  @override
  Future<void> acknowledgeSubmission({
    required String outboxId,
    required String acknowledgementJson,
  }) {
    return localDataSource.acknowledgeSubmissionAtomically(
      outboxId: outboxId,
      acknowledgementJson: acknowledgementJson,
    );
  }

  @override
  Future<void> markSubmissionFailed({
    required String outboxId,
    required FailureCategory category,
    required DateTime? nextEligibleAttemptAt,
  }) {
    return localDataSource.markSubmissionFailed(
      outboxId: outboxId,
      category: category,
      nextEligibleAttemptAt: nextEligibleAttemptAt,
    );
  }

  @override
  Future<void> blockSubmission({
    required String outboxId,
    required FailureCategory category,
  }) {
    return localDataSource.blockSubmission(
      outboxId: outboxId,
      category: category,
    );
  }

  @override
  Future<int> recoverExpiredLeases() {
    return localDataSource.recoverExpiredLeases();
  }

  @override
  Future<SubmissionRecord?> getOutboxByOperationKey(String operationKey) {
    return localDataSource.getOutboxByOperationKey(operationKey);
  }

  @override
  Future<SubmissionRecord?> getOutboxForLesson({
    required String learnerId,
    required String lessonId,
  }) {
    return localDataSource.getOutboxForLesson(
      learnerId: learnerId,
      lessonId: lessonId,
    );
  }
}
