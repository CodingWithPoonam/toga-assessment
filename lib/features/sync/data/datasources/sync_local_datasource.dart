import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/encryption_service.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../domain/entities/outbox_enums.dart';
import '../../domain/entities/submission_record.dart';
import '../../domain/entities/submission_snapshot.dart';

/// Local data source managing SubmissionOutbox persistence and atomic staging transactions
class SyncLocalDataSource {
  final AppDatabase database;
  final IEncryptionService encryptionService;

  SyncLocalDataSource({
    required this.database,
    required this.encryptionService,
  });

  /// Maps Drift row to immutable domain entity
  SubmissionRecord _mapRow(SubmissionOutboxData row) {
    return SubmissionRecord(
      id: row.id,
      learnerId: row.learnerId,
      lessonId: row.lessonId,
      revisionId: row.revisionId,
      operationKey: row.operationKey,
      encryptedPayload: row.encryptedPayload,
      status: OutboxStatus.fromString(row.status),
      attemptCount: row.attemptCount,
      createdAt: row.createdAt,
      lastAttemptedAt: row.lastAttemptedAt,
      nextEligibleAttemptAt: row.nextEligibleAttemptAt,
      lastFailureCategory: FailureCategory.fromString(row.lastFailureCategory),
      leaseExpiresAt: row.leaseExpiresAt,
      serverAcknowledgement: row.serverAcknowledgement,
    );
  }

  /// Atomically stages an in-progress draft into the outbox within one transaction
  Future<SubmissionRecord> stageSubmissionAtomically({
    required String learnerId,
    required String lessonId,
  }) async {
    // 1. Fetch draft and verify ownership
    final draftQuery = database.select(database.quizDrafts)
      ..where(
        (tbl) =>
            tbl.learnerId.equals(learnerId) & tbl.lessonId.equals(lessonId),
      );
    final draftRow = await draftQuery.getSingleOrNull();

    if (draftRow == null) {
      throw const ServerFailure(
        'Cannot stage submission: quiz draft not found',
      );
    }

    // 2. Check if an active (pending/in_flight) outbox entry already exists
    final existingActiveQuery = database.select(database.submissionOutbox)
      ..where(
        (tbl) =>
            tbl.learnerId.equals(learnerId) &
            tbl.lessonId.equals(lessonId) &
            tbl.status.isIn(['pending', 'in_flight', 'retry_scheduled']),
      );
    final existingActive = await existingActiveQuery.getSingleOrNull();
    if (existingActive != null) {
      return _mapRow(existingActive);
    }

    // 3. Fetch encrypted answers and decrypt using question-level AAD
    final answersQuery = database.select(database.quizAnswers)
      ..where((tbl) => tbl.draftId.equals(draftRow.id));
    final answerRows = await answersQuery.get();

    final Map<String, String> answers = {};
    for (final row in answerRows) {
      try {
        final aad =
            '$learnerId:${draftRow.lessonId}:${draftRow.revisionId}:${row.questionId}';
        final decrypted = await encryptionService.decrypt(
          cipherText: row.encryptedSelectedOptionId,
          associatedData: aad,
        );
        answers[row.questionId] = decrypted;
      } catch (_) {
        // Discard corrupted answers
      }
    }

    if (answers.isEmpty) {
      throw const ServerFailure(
        'Cannot stage submission: draft has no valid answers',
      );
    }

    // 4. Generate stable UUID operationKey and construct immutable snapshot
    final outboxId = UuidGenerator.v4();
    final operationKey = UuidGenerator.v4();
    final now = DateTime.now();

    final snapshot = SubmissionSnapshot(
      operationKey: operationKey,
      learnerId: learnerId,
      lessonId: lessonId,
      revisionId: draftRow.revisionId,
      answers: answers,
      stagedAt: now,
    );

    // 5. Encrypt snapshot with canonical AAD
    final canonicalAad = snapshot.buildCanonicalAad();
    final encryptedPayload = await encryptionService.encrypt(
      plainText: jsonEncode(snapshot.toJson()),
      associatedData: canonicalAad,
    );

    // 6. Commit outbox entry and draft status update in one SQLite transaction
    return database.transaction(() async {
      await database
          .into(database.submissionOutbox)
          .insert(
            SubmissionOutboxCompanion(
              id: Value(outboxId),
              learnerId: Value(learnerId),
              lessonId: Value(lessonId),
              revisionId: Value(draftRow.revisionId),
              operationKey: Value(operationKey),
              encryptedPayload: Value(encryptedPayload),
              status: const Value('pending'),
              attemptCount: const Value(0),
              createdAt: Value(now),
            ),
          );

      await (database.update(
        database.quizDrafts,
      )..where((tbl) => tbl.id.equals(draftRow.id))).write(
        QuizDraftsCompanion(
          draftStatus: const Value('staged'),
          isSubmitted: const Value(true),
          updatedAt: Value(now),
        ),
      );

      final inserted = await (database.select(
        database.submissionOutbox,
      )..where((tbl) => tbl.id.equals(outboxId))).getSingle();

      return _mapRow(inserted);
    });
  }

  /// Atomically claims a pending or retryable submission with a time-bounded lease
  Future<SubmissionRecord?> claimSubmissionForSync({
    required String outboxId,
    required Duration leaseDuration,
  }) async {
    final now = DateTime.now();
    final leaseExpiresAt = now.add(leaseDuration);

    return database.transaction(() async {
      final query = database.select(database.submissionOutbox)
        ..where(
          (tbl) =>
              tbl.id.equals(outboxId) &
              tbl.status.isIn(['pending', 'retry_scheduled']),
        );
      final record = await query.getSingleOrNull();

      if (record == null) return null;

      final updatedAttemptCount = record.attemptCount + 1;

      await (database.update(
        database.submissionOutbox,
      )..where((tbl) => tbl.id.equals(outboxId))).write(
        SubmissionOutboxCompanion(
          status: const Value('in_flight'),
          leaseExpiresAt: Value(leaseExpiresAt),
          lastAttemptedAt: Value(now),
          attemptCount: Value(updatedAttemptCount),
        ),
      );

      final updated = await (database.select(
        database.submissionOutbox,
      )..where((tbl) => tbl.id.equals(outboxId))).getSingle();

      return _mapRow(updated);
    });
  }

  /// Atomically commits server acknowledgement, completes outbox, and acknowledges draft
  Future<void> acknowledgeSubmissionAtomically({
    required String outboxId,
    required String acknowledgementJson,
  }) async {
    final now = DateTime.now();

    await database.transaction(() async {
      final outboxRecord = await (database.select(
        database.submissionOutbox,
      )..where((tbl) => tbl.id.equals(outboxId))).getSingleOrNull();

      if (outboxRecord == null) return;

      // 1. Complete outbox record
      await (database.update(
        database.submissionOutbox,
      )..where((tbl) => tbl.id.equals(outboxId))).write(
        SubmissionOutboxCompanion(
          status: const Value('completed'),
          serverAcknowledgement: Value(acknowledgementJson),
          leaseExpiresAt: const Value(null),
          lastAttemptedAt: Value(now),
        ),
      );

      // 2. Mark draft acknowledged
      await (database.update(database.quizDrafts)..where(
            (tbl) =>
                tbl.learnerId.equals(outboxRecord.learnerId) &
                tbl.lessonId.equals(outboxRecord.lessonId),
          ))
          .write(
            QuizDraftsCompanion(
              draftStatus: const Value('acknowledged'),
              isSubmitted: const Value(true),
              updatedAt: Value(now),
            ),
          );
    });
  }

  /// Updates outbox for a transient retry failure
  Future<void> markSubmissionFailed({
    required String outboxId,
    required FailureCategory category,
    required DateTime? nextEligibleAttemptAt,
  }) async {
    await (database.update(
      database.submissionOutbox,
    )..where((tbl) => tbl.id.equals(outboxId))).write(
      SubmissionOutboxCompanion(
        status: const Value('retry_scheduled'),
        lastFailureCategory: Value(category.value),
        nextEligibleAttemptAt: Value(nextEligibleAttemptAt),
        leaseExpiresAt: const Value(null),
      ),
    );
  }

  /// Blocks submission permanently and marks draft blocked
  Future<void> blockSubmission({
    required String outboxId,
    required FailureCategory category,
  }) async {
    await database.transaction(() async {
      final outboxRecord = await (database.select(
        database.submissionOutbox,
      )..where((tbl) => tbl.id.equals(outboxId))).getSingleOrNull();

      if (outboxRecord == null) return;

      await (database.update(
        database.submissionOutbox,
      )..where((tbl) => tbl.id.equals(outboxId))).write(
        SubmissionOutboxCompanion(
          status: const Value('blocked'),
          lastFailureCategory: Value(category.value),
          leaseExpiresAt: const Value(null),
        ),
      );

      await (database.update(database.quizDrafts)..where(
            (tbl) =>
                tbl.learnerId.equals(outboxRecord.learnerId) &
                tbl.lessonId.equals(outboxRecord.lessonId),
          ))
          .write(
            QuizDraftsCompanion(
              draftStatus: const Value('blocked'),
              updatedAt: Value(DateTime.now()),
            ),
          );
    });
  }

  /// Recovers in_flight submissions whose lease has expired
  Future<int> recoverExpiredLeases() async {
    final now = DateTime.now();
    final expiredQuery = database.select(database.submissionOutbox)
      ..where(
        (tbl) =>
            tbl.status.equals('in_flight') &
            tbl.leaseExpiresAt.isSmallerThanValue(now),
      );
    final expired = await expiredQuery.get();

    for (final row in expired) {
      final nextStatus = row.attemptCount >= 3 ? 'retry_scheduled' : 'pending';
      await (database.update(
        database.submissionOutbox,
      )..where((tbl) => tbl.id.equals(row.id))).write(
        SubmissionOutboxCompanion(
          status: Value(nextStatus),
          leaseExpiresAt: const Value(null),
        ),
      );
    }
    return expired.length;
  }

  /// Retrieves pending or retryable submissions for an authenticated learner
  Future<List<SubmissionRecord>> getPendingSubmissions(String learnerId) async {
    final now = DateTime.now();
    final query = database.select(database.submissionOutbox)
      ..where(
        (tbl) =>
            tbl.learnerId.equals(learnerId) &
            (tbl.status.equals('pending') |
                (tbl.status.equals('retry_scheduled') &
                    (tbl.nextEligibleAttemptAt.isNull() |
                        tbl.nextEligibleAttemptAt.isSmallerOrEqualValue(now)))),
      )
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);

    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  Future<SubmissionRecord?> getOutboxByOperationKey(String operationKey) async {
    final query = database.select(database.submissionOutbox)
      ..where((tbl) => tbl.operationKey.equals(operationKey));
    final row = await query.getSingleOrNull();
    return row != null ? _mapRow(row) : null;
  }

  Future<SubmissionRecord?> getOutboxForLesson({
    required String learnerId,
    required String lessonId,
  }) async {
    final query = database.select(database.submissionOutbox)
      ..where(
        (tbl) =>
            tbl.learnerId.equals(learnerId) & tbl.lessonId.equals(lessonId),
      )
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    final row = await query.getSingleOrNull();
    return row != null ? _mapRow(row) : null;
  }
}
