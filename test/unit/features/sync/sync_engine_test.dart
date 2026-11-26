import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:toga_assessment/core/database/app_database.dart';
import 'package:toga_assessment/core/security/encryption_service.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';
import 'package:toga_assessment/core/security/session_manager.dart';
import 'package:toga_assessment/features/quiz/data/datasources/quiz_local_datasource.dart';
import 'package:toga_assessment/features/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:toga_assessment/features/quiz/data/datasources/quiz_fixture_datasource.dart';
import 'package:toga_assessment/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:toga_assessment/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:toga_assessment/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:toga_assessment/features/sync/domain/entities/outbox_enums.dart';
import 'package:toga_assessment/features/sync/domain/entities/sync_result.dart';
import 'package:toga_assessment/features/sync/domain/usecases/sync_engine.dart';

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
  late SyncRemoteDataSource remoteDataSource;
  late SyncRepositoryImpl syncRepository;
  late SyncEngine syncEngine;

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
    remoteDataSource = SyncRemoteDataSource(simulatedLatency: Duration.zero);
    syncRepository = SyncRepositoryImpl(
      localDataSource: syncLocalDataSource,
      sessionManager: sessionManager,
    );

    syncEngine = SyncEngine(
      syncRepository: syncRepository,
      remoteDataSource: remoteDataSource,
      encryptionService: encryptionService,
      sessionManager: sessionManager,
      leaseDuration: const Duration(seconds: 30),
      maxAttempts: 3,
      maxForegroundBudget: const Duration(seconds: 10),
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

  group('SyncEngine Bounded Foreground Synchronization', () {
    test(
      'Successfully synchronizes staged attempt: commits ACK and acknowledges draft',
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

        final result = await syncEngine.synchronize(learnerId: 'learner-a');
        expect(result.outcome, equals(SyncOutcomeStatus.success));
        expect(result.operationKey, equals(staged.operationKey));
        expect(result.receiptId, isNotNull);

        // Verify outbox updated in SQLite
        final outbox = await syncRepository.getOutboxByOperationKey(
          staged.operationKey,
        );
        expect(outbox!.status, equals(OutboxStatus.completed));
        expect(outbox.serverAcknowledgement, isNotNull);

        // Verify draft marked acknowledged
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

    test(
      'Idempotency: Lost response retried with identical operationKey returns original receipt',
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

        // 1. Simulate server commit where response connection dropped before reaching client
        remoteDataSource.simulateCommitWithLostResponse = true;

        final firstRun = await syncEngine.synchronize(learnerId: 'learner-a');
        expect(firstRun.outcome, equals(SyncOutcomeStatus.transientFailure));

        // Outbox status should be retry_scheduled with attemptCount 1
        final outboxAttempt1 = await syncRepository.getOutboxByOperationKey(
          staged.operationKey,
        );
        expect(outboxAttempt1!.status, equals(OutboxStatus.retryScheduled));
        expect(outboxAttempt1.attemptCount, equals(1));

        // 2. Clear next eligible attempt delay for immediate retry
        await syncRepository.markSubmissionFailed(
          outboxId: staged.id,
          category: FailureCategory.network,
          nextEligibleAttemptAt: null,
        );

        // 3. Retry run: sends exact same operationKey
        final retryRun = await syncEngine.synchronize(learnerId: 'learner-a');
        expect(retryRun.outcome, equals(SyncOutcomeStatus.success));
        expect(retryRun.operationKey, equals(staged.operationKey));

        final outboxFinal = await syncRepository.getOutboxByOperationKey(
          staged.operationKey,
        );
        expect(outboxFinal!.status, equals(OutboxStatus.completed));
      },
    );

    test(
      'Stale content conflict: server rejects revision mismatch &rarr; blocks outbox and preserves draft',
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

        // Simulate server stale content rejection
        remoteDataSource.simulateStaleContentError = true;

        final result = await syncEngine.synchronize(learnerId: 'learner-a');
        expect(result.outcome, equals(SyncOutcomeStatus.blocked));

        final outbox = await syncRepository.getOutboxByOperationKey(
          staged.operationKey,
        );
        expect(outbox!.status, equals(OutboxStatus.blocked));
        expect(
          outbox.lastFailureCategory,
          equals(FailureCategory.staleContent),
        );

        // Draft is preserved and marked blocked
        final rawDraft =
            await (database.select(database.quizDrafts)..where(
                  (tbl) =>
                      tbl.learnerId.equals('learner-a') &
                      tbl.lessonId.equals('provisional_lesson_1'),
                ))
                .getSingle();
        expect(rawDraft.draftStatus, equals('blocked'));
      },
    );

    test(
      'Session generation safety: account switch during upload returns sessionInvalidated',
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

        // Create a remote data source that switches session during upload call
        final switchingRemoteSource = _SessionSwitchingRemoteDataSource(
          sessionManager: sessionManager,
        );

        final testEngine = SyncEngine(
          syncRepository: syncRepository,
          remoteDataSource: switchingRemoteSource,
          encryptionService: encryptionService,
          sessionManager: sessionManager,
        );

        final result = await testEngine.synchronize(learnerId: 'learner-a');
        expect(result.outcome, equals(SyncOutcomeStatus.sessionInvalidated));

        // Server ACK is still persisted to database for learner-a
        final outbox = await syncRepository.getOutboxByOperationKey(
          staged.operationKey,
        );
        expect(outbox!.status, equals(OutboxStatus.completed));
      },
    );

    test(
      'Bounded foreground budget: stops and returns budgetExhausted when deadline is exceeded',
      () async {
        await quizRepository.saveAnswer(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
          questionId: 'q1',
          optionId: 'opt_1c',
          currentQuestionIndex: 0,
        );

        await syncRepository.stageSubmission(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
        );

        // Configure engine with zero budget to immediately exhaust budget
        final zeroBudgetEngine = SyncEngine(
          syncRepository: syncRepository,
          remoteDataSource: remoteDataSource,
          encryptionService: encryptionService,
          sessionManager: sessionManager,
          maxForegroundBudget: Duration.zero,
        );

        final result = await zeroBudgetEngine.synchronize(
          learnerId: 'learner-a',
        );
        expect(result.outcome, equals(SyncOutcomeStatus.budgetExhausted));
      },
    );
  });
}

class _SessionSwitchingRemoteDataSource extends SyncRemoteDataSource {
  final ISessionManager sessionManager;

  _SessionSwitchingRemoteDataSource({required this.sessionManager});

  @override
  Future<SyncSubmissionResponse> submitQuizAttempt({
    required dynamic snapshot,
    required String operationKey,
  }) async {
    // Invalidate session mid-request (simulate logout / switch to learner-b)
    await sessionManager.setSession(
      learnerId: 'learner-b',
      accessToken: 'token_b',
      refreshToken: 'refresh_b',
    );

    return SyncSubmissionResponse(
      receiptId: 'receipt_interrupted_123',
      operationKey: operationKey,
      lessonId: 'provisional_lesson_1',
      revisionId: 'rev_1_0',
      acknowledgedAt: DateTime.now(),
    );
  }
}
