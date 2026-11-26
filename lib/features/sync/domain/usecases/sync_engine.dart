import 'dart:convert';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/security/encryption_service.dart';
import '../../../../core/security/session_manager.dart';
import '../../data/datasources/sync_remote_datasource.dart';
import '../entities/outbox_enums.dart';
import '../entities/submission_snapshot.dart';
import '../entities/sync_result.dart';
import '../repositories/sync_repository.dart';

/// Contract for the bounded foreground synchronization engine
abstract class ISyncEngine {
  Future<SyncResult> synchronize({required String learnerId});
}

/// Synchronization engine executing bounded, idempotent outbox uploads
class SyncEngine implements ISyncEngine {
  final SyncRepository syncRepository;
  final SyncRemoteDataSource remoteDataSource;
  final IEncryptionService encryptionService;
  final ISessionManager sessionManager;
  final Duration leaseDuration;
  final int maxAttempts;
  final Duration maxForegroundBudget;

  SyncEngine({
    required this.syncRepository,
    required this.remoteDataSource,
    required this.encryptionService,
    required this.sessionManager,
    this.leaseDuration = const Duration(seconds: 60),
    this.maxAttempts = 3,
    this.maxForegroundBudget = const Duration(seconds: 10),
  });

  @override
  Future<SyncResult> synchronize({required String learnerId}) async {
    final stopwatch = Stopwatch()..start();

    // 1. Recover expired leases before processing new work
    await syncRepository.recoverExpiredLeases();

    // 2. Validate authenticated learner session
    final activeLearnerId = sessionManager.activeLearnerId;
    if (activeLearnerId == null || activeLearnerId != learnerId) {
      return SyncResult.sessionInvalidated();
    }

    // 3. Find eligible pending submissions
    final pendingRecords = await syncRepository.getPendingSubmissions(
      learnerId,
    );
    if (pendingRecords.isEmpty) {
      return SyncResult.idle();
    }

    // 4. Process records within bounded foreground budget
    for (final record in pendingRecords) {
      if (stopwatch.elapsed >= maxForegroundBudget) {
        return SyncResult.budgetExhausted(elapsed: stopwatch.elapsed);
      }

      // Check max attempt ceiling
      if (record.attemptCount >= maxAttempts) {
        continue;
      }

      // Atomically claim the record
      final claimed = await syncRepository.claimSubmissionForSync(
        outboxId: record.id,
        leaseDuration: leaseDuration,
      );

      if (claimed == null) {
        // Already claimed by a concurrent trigger
        continue;
      }

      // Capture session generation at the moment of request dispatch
      final startGeneration = sessionManager.sessionGeneration;

      // Reconstruct canonical AAD and decrypt immutable snapshot
      final canonicalAad = jsonEncode({
        'learnerId': claimed.learnerId,
        'lessonId': claimed.lessonId,
        'operationKey': claimed.operationKey,
        'revisionId': claimed.revisionId,
      });

      SubmissionSnapshot snapshot;
      try {
        final clearJson = await encryptionService.decrypt(
          cipherText: claimed.encryptedPayload,
          associatedData: canonicalAad,
        );
        snapshot = SubmissionSnapshot.fromJson(
          jsonDecode(clearJson) as Map<String, dynamic>,
        );
      } catch (e) {
        // AAD or ciphertext corruption - fail permanently without falling back
        await syncRepository.blockSubmission(
          outboxId: claimed.id,
          category: FailureCategory.validation,
        );
        return SyncResult.blocked(
          outboxId: claimed.id,
          reason: 'Decryption failed: AAD mismatch or corrupted payload',
          elapsed: stopwatch.elapsed,
        );
      }

      // Remote HTTP dispatch with idempotent operationKey
      try {
        final response = await remoteDataSource.submitQuizAttempt(
          snapshot: snapshot,
          operationKey: claimed.operationKey,
        );

        // Verify session generation has not changed mid-upload
        final sessionStillValid = sessionManager.isGenerationValid(
          startGeneration,
        );

        // Atomically commit server acknowledgement into SQLite
        await syncRepository.acknowledgeSubmission(
          outboxId: claimed.id,
          acknowledgementJson: jsonEncode(response.toJson()),
        );

        if (!sessionStillValid) {
          // Response committed to database for the owning learner,
          // but active session switched during flight: do not mutate current session UI
          return SyncResult.sessionInvalidated();
        }

        return SyncResult.success(
          outboxId: claimed.id,
          operationKey: claimed.operationKey,
          receiptId: response.receiptId,
          elapsed: stopwatch.elapsed,
        );
      } on ConflictException catch (e) {
        // Stale content response: revision conflict detected by server
        await syncRepository.blockSubmission(
          outboxId: claimed.id,
          category: FailureCategory.staleContent,
        );
        return SyncResult.blocked(
          outboxId: claimed.id,
          reason: e.message,
          elapsed: stopwatch.elapsed,
        );
      } on ApiException catch (e) {
        // Transient network failure, timeout, 429, 503: compute exponential backoff and schedule retry
        final backoffSeconds = 1 << claimed.attemptCount;
        final nextAttempt = DateTime.now().add(
          Duration(seconds: backoffSeconds),
        );

        await syncRepository.markSubmissionFailed(
          outboxId: claimed.id,
          category: FailureCategory.network,
          nextEligibleAttemptAt: nextAttempt,
        );

        // Check if session changed during network call
        if (!sessionManager.isGenerationValid(startGeneration)) {
          return SyncResult.sessionInvalidated();
        }

        return SyncResult.transientFailure(
          outboxId: claimed.id,
          message: e.message,
          elapsed: stopwatch.elapsed,
        );
      } catch (e) {
        await syncRepository.markSubmissionFailed(
          outboxId: claimed.id,
          category: FailureCategory.serverError,
          nextEligibleAttemptAt: DateTime.now().add(const Duration(seconds: 5)),
        );
        return SyncResult.transientFailure(
          outboxId: claimed.id,
          message: e.toString(),
          elapsed: stopwatch.elapsed,
        );
      }
    }

    return SyncResult.idle();
  }
}
