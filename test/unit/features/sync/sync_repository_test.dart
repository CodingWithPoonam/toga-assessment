import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:toga_assessment/core/database/app_database.dart';
import 'package:toga_assessment/core/errors/exceptions.dart';
import 'package:toga_assessment/core/security/encryption_service.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';
import 'package:toga_assessment/core/security/session_manager.dart';
import 'package:toga_assessment/features/quiz/data/datasources/quiz_local_datasource.dart';
import 'package:toga_assessment/features/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:toga_assessment/features/quiz/data/datasources/quiz_fixture_datasource.dart';
import 'package:toga_assessment/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:toga_assessment/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:toga_assessment/features/sync/domain/entities/outbox_enums.dart';

class InMemorySecureStorage implements ISecureStorage {
  final Map<String, String> _map = {};

  @override
  Future<bool> containsKey(String key) async => _map.containsKey(key);

  @override
  Future<void> delete(String key) async => _map.remove(key);

  @override
  Future<void> deleteAll() async => _map.clear();

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;
}

void main() {
  late AppDatabase database;
  late ISecureStorage secureStorage;
  late IEncryptionService encryptionService;
  late ISessionManager sessionManager;
  late QuizLocalDataSource quizLocalDataSource;
  late QuizRepositoryImpl quizRepository;
  late SyncLocalDataSource syncLocalDataSource;
  late SyncRepositoryImpl syncRepository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    secureStorage = InMemorySecureStorage();
    encryptionService = AesGcmEncryptionService(secureStorage: secureStorage);
    sessionManager = SessionManager(secureStorage: secureStorage);

    quizLocalDataSource = QuizLocalDataSource(
      database: database,
      encryptionService: encryptionService,
    );
    quizRepository = QuizRepositoryImpl(
      localDataSource: quizLocalDataSource,
      fixtureDataSource: QuizFixtureDataSource(),
      sessionManager: sessionManager,
    );

    syncLocalDataSource = SyncLocalDataSource(
      database: database,
      encryptionService: encryptionService,
    );
    syncRepository = SyncRepositoryImpl(
      localDataSource: syncLocalDataSource,
      sessionManager: sessionManager,
    );

    await sessionManager.setSession(
      learnerId: 'learner-a',
      accessToken: 'token_a',
      refreshToken: 'refresh_a',
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('SyncRepositoryImpl & Outbox Transactions', () {
    test(
      'Atomically stages draft into outbox: marks draft staged and preserves draft',
      () async {
        // 1. Answer questions in quiz
        await quizRepository.saveAnswer(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
          questionId: 'q1',
          optionId: 'opt_1c',
          currentQuestionIndex: 0,
        );

        // 2. Stage submission
        final staged = await syncRepository.stageSubmission(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
        );

        expect(staged.learnerId, equals('learner-a'));
        expect(staged.lessonId, equals('provisional_lesson_1'));
        expect(staged.revisionId, equals('rev_1_0'));
        expect(staged.status, equals(OutboxStatus.pending));
        expect(staged.operationKey, isNotEmpty);
        expect(staged.encryptedPayload, isNotEmpty);

        // 3. Verify original draft is PRESERVED and marked staged
        final draft = await quizRepository.getDraft(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
        );
        expect(draft, isNotNull);
        expect(draft!.isSubmitted, isTrue);

        final rawDraft = await (database.select(
          database.quizDrafts,
        )..where((tbl) => tbl.id.equals(draft.id))).getSingle();
        expect(rawDraft.draftStatus, equals('staged'));
      },
    );

    test(
      'Duplicate staging requests reuse existing pending outbox entry without duplicating',
      () async {
        await quizRepository.saveAnswer(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
          questionId: 'q1',
          optionId: 'opt_1c',
          currentQuestionIndex: 0,
        );

        final staged1 = await syncRepository.stageSubmission(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
        );

        final staged2 = await syncRepository.stageSubmission(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
        );

        expect(staged2.id, equals(staged1.id));
        expect(staged2.operationKey, equals(staged1.operationKey));

        final allOutbox = await database
            .select(database.submissionOutbox)
            .get();
        expect(allOutbox.length, 1);
      },
    );

    test(
      'Tenant isolation: Learner B cannot stage or access Learner A draft',
      () async {
        await quizRepository.saveAnswer(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
          questionId: 'q1',
          optionId: 'opt_1c',
          currentQuestionIndex: 0,
        );

        // Attempt to stage with mismatched learnerId throws SecurityException
        expect(
          () => syncRepository.stageSubmission(
            learnerId: 'learner-b',
            lessonId: 'provisional_lesson_1',
          ),
          throwsA(isA<SecurityException>()),
        );
      },
    );

    test(
      'Claims submission with bounded lease duration and increments attempt count',
      () async {
        await quizRepository.saveAnswer(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
          questionId: 'q1',
          optionId: 'opt_1c',
          currentQuestionIndex: 0,
        );

        final staged = await syncRepository.stageSubmission(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
        );

        final claimed = await syncRepository.claimSubmissionForSync(
          outboxId: staged.id,
          leaseDuration: const Duration(seconds: 30),
        );

        expect(claimed, isNotNull);
        expect(claimed!.status, equals(OutboxStatus.inFlight));
        expect(claimed.attemptCount, equals(1));
        expect(claimed.leaseExpiresAt, isNotNull);

        // Concurrent claim on the same record returns null (already in_flight)
        final concurrentClaim = await syncRepository.claimSubmissionForSync(
          outboxId: staged.id,
          leaseDuration: const Duration(seconds: 30),
        );
        expect(concurrentClaim, isNull);
      },
    );

    test(
      'Atomically acknowledges submission: updates outbox to completed and draft to acknowledged',
      () async {
        await quizRepository.saveAnswer(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
          questionId: 'q1',
          optionId: 'opt_1c',
          currentQuestionIndex: 0,
        );

        final staged = await syncRepository.stageSubmission(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
        );

        const receipt = '{"receiptId":"rcpt_123","status":"accepted"}';
        await syncRepository.acknowledgeSubmission(
          outboxId: staged.id,
          acknowledgementJson: receipt,
        );

        final updatedOutbox = await syncRepository.getOutboxByOperationKey(
          staged.operationKey,
        );
        expect(updatedOutbox!.status, equals(OutboxStatus.completed));
        expect(updatedOutbox.serverAcknowledgement, equals(receipt));

        final rawDraft =
            await (database.select(database.quizDrafts)..where(
                  (tbl) =>
                      tbl.learnerId.equals('learner-a') &
                      tbl.lessonId.equals('provisional_lesson_1'),
                ))
                .getSingle();
        expect(rawDraft.draftStatus, equals('acknowledged'));
      },
    );

    test('Recovers expired in_flight leases back to pending', () async {
      await quizRepository.saveAnswer(
        learnerId: 'learner-a',
        lessonId: 'provisional_lesson_1',
        revisionId: 'rev_1_0',
        questionId: 'q1',
        optionId: 'opt_1c',
        currentQuestionIndex: 0,
      );

      final staged = await syncRepository.stageSubmission(
        learnerId: 'learner-a',
        lessonId: 'provisional_lesson_1',
      );

      // Claim with negative duration to immediately expire lease
      await syncRepository.claimSubmissionForSync(
        outboxId: staged.id,
        leaseDuration: const Duration(seconds: -10),
      );

      final recoveredCount = await syncRepository.recoverExpiredLeases();
      expect(recoveredCount, equals(1));

      final recovered = await syncRepository.getOutboxByOperationKey(
        staged.operationKey,
      );
      expect(recovered!.status, equals(OutboxStatus.pending));
    });
  });
}
