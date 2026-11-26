import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:toga_assessment/app/app.dart';
import 'package:toga_assessment/core/database/app_database.dart';
import 'package:toga_assessment/core/di/injection.dart';
import 'package:toga_assessment/core/errors/exceptions.dart';
import 'package:toga_assessment/core/network/network_config.dart';
import 'package:toga_assessment/core/security/encryption_service.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';
import 'package:toga_assessment/core/security/session_manager.dart';
import 'package:toga_assessment/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:toga_assessment/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:toga_assessment/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:toga_assessment/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:toga_assessment/features/sync/domain/entities/outbox_enums.dart';
import 'package:toga_assessment/features/sync/domain/entities/sync_result.dart';
import 'package:toga_assessment/features/sync/domain/repositories/sync_repository.dart';
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
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dbFile;
  late ISecureStorage secureStorage;
  late ISessionManager sessionManager;
  late AuthRemoteDataSource authRemoteDataSource;
  late SyncRemoteDataSource syncRemoteDataSource;
  late AppDatabase database;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('toga_e2e_');
    dbFile = File(p.join(tempDir.path, 'e2e_toga.sqlite'));
    secureStorage = InMemorySecureStorage();
    sessionManager = SessionManager(secureStorage: secureStorage);
    authRemoteDataSource = MockAuthRemoteDataSource(
      networkLatency: Duration.zero,
    );
    syncRemoteDataSource = SyncRemoteDataSource(simulatedLatency: Duration.zero);
    database = AppDatabase(NativeDatabase(dbFile));

    await configureDependencies(
      networkConfig: NetworkConfig.development(),
      secureStorageOverride: secureStorage,
      sessionManagerOverride: sessionManager,
      remoteDataSourceOverride: authRemoteDataSource,
      authRepositoryOverride: AuthRepositoryImpl(
        remoteDataSource: authRemoteDataSource,
        sessionManager: sessionManager,
      ),
      syncRemoteDataSourceOverride: syncRemoteDataSource,
      databaseOverride: database,
    );
  });

  tearDown(() async {
    try {
      await database.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('End-to-End Offline-to-Online Integration Journey', () {
    testWidgets(
      'Complete 18-step journey: Login, cache reading, offline quiz answering, persistent draft restart, and outbox sync',
      (WidgetTester tester) async {
        // STEP 1: Start application with clean test database
        await tester.pumpWidget(const TogaApp());
        await tester.pumpAndSettle();

        expect(find.text('AIRMAN TOGA Login'), findsOneWidget);
        expect(find.text('Alex Mercer (Learner A)'), findsOneWidget);

        // STEP 2: Authenticate using synthetic learner fixture
        await tester.ensureVisible(find.text('Authenticate & Enter'));
        await tester.tap(find.text('Authenticate & Enter'));
        await tester.pumpAndSettle();

        // STEP 3: Load lesson catalogue
        expect(find.text('Lesson Catalogue'), findsOneWidget);
        expect(find.text('Alex Mercer (Learner A)'), findsOneWidget);
        expect(find.text('Aerodynamics & Flight Principles'), findsOneWidget);

        // STEP 4: Open lesson with known content revision (provisional_lesson_1, rev_1_0)
        await tester.tap(find.text('Aerodynamics & Flight Principles'));
        await tester.pumpAndSettle();
        expect(find.text('Lesson Detail'), findsOneWidget);

        // STEP 5: Verify lesson content is cached in SQLite
        final cached = await (database.select(database.cachedLessons)
              ..where(
                (tbl) =>
                    tbl.id.equals('provisional_lesson_1') &
                    tbl.revisionId.equals('rev_1_0'),
              ))
            .getSingleOrNull();
        expect(cached, isNotNull);
        expect(cached!.title, equals('Aerodynamics & Flight Principles'));

        // STEP 6: Simulate loss of network connectivity
        syncRemoteDataSource.simulateNetworkDrop = true;

        // Open Quiz
        await tester.scrollUntilVisible(
          find.text('Take Lesson Quiz'),
          100.0,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('Take Lesson Quiz'));
        await tester.pumpAndSettle();

        expect(find.text('Lesson Quiz'), findsOneWidget);

        // STEP 7: Answer five quiz questions
        for (var i = 0; i < 5; i++) {
          expect(find.text('Question ${i + 1} of 5'), findsOneWidget);

          // Select first option card
          final optionCard = find.byType(Card).first;
          await tester.tap(optionCard);
          await tester.pumpAndSettle();

          if (i < 4) {
            // Tap Next Question
            await tester.tap(find.text('Next'));
            await tester.pumpAndSettle();
          }
        }

        // STEP 8: Verify encrypted answers and position are persisted
        final draft = await (database.select(database.quizDrafts)
              ..where(
                (tbl) =>
                    tbl.learnerId.equals('learner-a') &
                    tbl.lessonId.equals('provisional_lesson_1'),
              ))
            .getSingleOrNull();
        expect(draft, isNotNull);
        expect(draft!.revisionId, equals('rev_1_0'));
        expect(draft.currentQuestionIndex, equals(4));

        final savedAnswers = await (database.select(database.quizAnswers)
              ..where((tbl) => tbl.draftId.equals(draft.id)))
            .get();
        expect(savedAnswers.length, equals(5));
        // Verify ciphertext is encrypted (not plaintext 'opt_a')
        for (final ans in savedAnswers) {
          expect(ans.encryptedSelectedOptionId, isNot(equals('opt_a')));
        }

        // STEP 9: Stage submission using atomic outbox mechanism
        expect(find.text('Submit Attempt'), findsOneWidget);
        await tester.tap(find.text('Submit Attempt'));
        await tester.pumpAndSettle();

        // STEP 10: Verify stable operation key is generated and persisted in outbox
        final outboxBeforeRestart = await (database.select(
          database.submissionOutbox,
        )..where((tbl) => tbl.learnerId.equals('learner-a'))).get();
        expect(outboxBeforeRestart.length, equals(1));
        final initialOperationKey = outboxBeforeRestart.first.operationKey;
        expect(initialOperationKey, isNotEmpty);
        // Because network is offline, status deferred to retry_scheduled
        expect(
          outboxBeforeRestart.first.status,
          equals(OutboxStatus.retryScheduled.value),
        );

        // STEP 11: Simulate process termination and application restart
        // Close DB, reset DI, pump down widget tree
        await database.close();
        await getIt.reset();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();

        // STEP 12: Reinitialize application using same learner and persistent database file
        final restartedDb = AppDatabase(NativeDatabase(dbFile));
        database = restartedDb;
        await configureDependencies(
          networkConfig: NetworkConfig.development(),
          secureStorageOverride: secureStorage,
          sessionManagerOverride: sessionManager,
          remoteDataSourceOverride: authRemoteDataSource,
          authRepositoryOverride: AuthRepositoryImpl(
            remoteDataSource: authRemoteDataSource,
            sessionManager: sessionManager,
          ),
          syncRemoteDataSourceOverride: syncRemoteDataSource,
          databaseOverride: restartedDb,
        );

        await tester.pumpWidget(const TogaApp());
        await tester.pumpAndSettle();

        // If session was cleared/restarted, authenticate back in; if restored, already on catalogue
        if (find.text('Authenticate & Enter').evaluate().isNotEmpty) {
          await tester.tap(find.text('Authenticate & Enter'));
          await tester.pumpAndSettle();
        }
        expect(find.text('Lesson Catalogue'), findsOneWidget);

        // STEP 13: Verify same revision, answers, and staged position restored
        final restoredDraft = await (restartedDb.select(restartedDb.quizDrafts)
              ..where((tbl) => tbl.learnerId.equals('learner-a')))
            .getSingle();
        expect(restoredDraft.revisionId, equals('rev_1_0'));
        expect(restoredDraft.draftStatus, equals(DraftStatus.staged.value));

        final restoredOutbox = await (restartedDb.select(
          restartedDb.submissionOutbox,
        )..where((tbl) => tbl.learnerId.equals('learner-a'))).getSingle();
        expect(restoredOutbox.operationKey, equals(initialOperationKey));
        expect(
          restoredOutbox.status,
          equals(OutboxStatus.retryScheduled.value),
        );

        // STEP 14: Restore network connectivity
        syncRemoteDataSource.simulateNetworkDrop = false;

        // Allow backoff window to elapse so retry_scheduled becomes eligible
        await Future<void>.delayed(const Duration(seconds: 2));

        // STEP 15: Trigger foreground synchronization
        final syncEngine = getIt<ISyncEngine>();
        final syncResult = await syncEngine.synchronize(
          learnerId: 'learner-a',
        );
        expect(syncResult.outcome, equals(SyncOutcomeStatus.success));

        // STEP 16: Verify the SAME operation key was sent and processed
        expect(syncResult.operationKey, equals(initialOperationKey));

        // STEP 17: Verify server acknowledgement is persisted
        final completedOutbox = await (restartedDb.select(
          restartedDb.submissionOutbox,
        )..where((tbl) => tbl.operationKey.equals(initialOperationKey))).getSingle();
        expect(completedOutbox.status, equals(OutboxStatus.completed.value));
        expect(completedOutbox.serverAcknowledgement, isNotNull);
        expect(
          completedOutbox.serverAcknowledgement,
          contains('receipt_'),
        );

        // STEP 18: Verify outbox entry cannot be submitted again as a new logical operation
        final subsequentSync = await syncEngine.synchronize(
          learnerId: 'learner-a',
        );
        expect(subsequentSync.outcome, equals(SyncOutcomeStatus.idle));

        final finalDraft = await (restartedDb.select(restartedDb.quizDrafts)
              ..where((tbl) => tbl.learnerId.equals('learner-a')))
            .getSingle();
        expect(finalDraft.draftStatus, equals(DraftStatus.acknowledged.value));
      },
    );

    testWidgets('Failure Validation: Lost response reconciles with identical operationKey', (
      WidgetTester tester,
    ) async {
      await sessionManager.setSession(
        learnerId: 'learner-a',
        accessToken: 'mem_token_a',
        refreshToken: 'sec_token_a',
      );

      final syncEngine = getIt<ISyncEngine>();
      final syncRepo = getIt<SyncRepository>();
      final quizRepo = getIt<QuizRepository>();

      // Create draft first
      await quizRepo.saveAnswer(
        learnerId: 'learner-a',
        lessonId: 'provisional_lesson_1',
        revisionId: 'rev_1_0',
        questionId: 'q1',
        optionId: 'opt_1a',
        currentQuestionIndex: 0,
      );

      // Stage submission
      final record = await syncRepo.stageSubmission(
        learnerId: 'learner-a',
        lessonId: 'provisional_lesson_1',
      );

      // Simulate server commits but network response drops
      syncRemoteDataSource.simulateCommitWithLostResponse = true;

      final firstAttempt = await syncEngine.synchronize(
        learnerId: 'learner-a',
      );
      expect(firstAttempt.outcome, equals(SyncOutcomeStatus.transientFailure));

      // Wait for backoff window to elapse
      await Future<void>.delayed(const Duration(seconds: 2));

      // Retry reconciles using identical operationKey without duplicate grading
      final retryAttempt = await syncEngine.synchronize(
        learnerId: 'learner-a',
      );
      expect(retryAttempt.outcome, equals(SyncOutcomeStatus.success));
      expect(retryAttempt.operationKey, equals(record.operationKey));
    });

    testWidgets('Failure Validation: Expired lease is recovered to pending', (
      WidgetTester tester,
    ) async {
      await sessionManager.setSession(
        learnerId: 'learner-a',
        accessToken: 'mem_token_a',
        refreshToken: 'sec_token_a',
      );

      final syncRepo = getIt<SyncRepository>();
      final quizRepo = getIt<QuizRepository>();

      // Create draft first
      await quizRepo.saveAnswer(
        learnerId: 'learner-a',
        lessonId: 'provisional_lesson_1',
        revisionId: 'rev_1_0',
        questionId: 'q1',
        optionId: 'opt_1a',
        currentQuestionIndex: 0,
      );

      final record = await syncRepo.stageSubmission(
        learnerId: 'learner-a',
        lessonId: 'provisional_lesson_1',
      );

      // Claim record with negative lease duration so it is immediately expired
      await syncRepo.claimSubmissionForSync(
        outboxId: record.id,
        leaseDuration: const Duration(seconds: -10),
      );

      // Reclaim expired lease
      final recoveredCount = await syncRepo.recoverExpiredLeases();
      expect(recoveredCount, equals(1));

      final outbox = await syncRepo.getOutboxByOperationKey(record.operationKey);
      expect(outbox!.status, equals(OutboxStatus.pending));
    });

    testWidgets('Failure Validation: Multi-tenant outbox isolation', (
      WidgetTester tester,
    ) async {
      // Stage under Learner A
      await sessionManager.setSession(
        learnerId: 'learner-a',
        accessToken: 'mem_token_a',
        refreshToken: 'sec_token_a',
      );

      final syncRepo = getIt<SyncRepository>();
      final syncEngine = getIt<ISyncEngine>();
      final quizRepo = getIt<QuizRepository>();

      // Create draft first
      await quizRepo.saveAnswer(
        learnerId: 'learner-a',
        lessonId: 'provisional_lesson_1',
        revisionId: 'rev_1_0',
        questionId: 'q1',
        optionId: 'opt_1a',
        currentQuestionIndex: 0,
      );

      await syncRepo.stageSubmission(
        learnerId: 'learner-a',
        lessonId: 'provisional_lesson_1',
      );

      // Switch session to Learner B
      await sessionManager.setSession(
        learnerId: 'learner-b',
        accessToken: 'mem_token_b',
        refreshToken: 'sec_token_b',
      );

      // Learner B processes outbox; must find 0 pending records and remain idle
      final resultLearnerB = await syncEngine.synchronize(
        learnerId: 'learner-b',
      );
      expect(resultLearnerB.outcome, equals(SyncOutcomeStatus.idle));
    });

    testWidgets('Failure Validation: Stale content revision blocks submission', (
      WidgetTester tester,
    ) async {
      await sessionManager.setSession(
        learnerId: 'learner-a',
        accessToken: 'mem_token_a',
        refreshToken: 'sec_token_a',
      );

      final syncRepo = getIt<SyncRepository>();
      final syncEngine = getIt<ISyncEngine>();
      final quizRepo = getIt<QuizRepository>();

      // Create draft first
      await quizRepo.saveAnswer(
        learnerId: 'learner-a',
        lessonId: 'provisional_lesson_1',
        revisionId: 'rev_1_0',
        questionId: 'q1',
        optionId: 'opt_1a',
        currentQuestionIndex: 0,
      );

      final record = await syncRepo.stageSubmission(
        learnerId: 'learner-a',
        lessonId: 'provisional_lesson_1',
      );

      // Simulate remote revision bump (stale content conflict)
      syncRemoteDataSource.simulateStaleContentError = true;

      final result = await syncEngine.synchronize(learnerId: 'learner-a');
      expect(result.outcome, equals(SyncOutcomeStatus.blocked));

      final outbox = await (database.select(database.submissionOutbox)
            ..where((tbl) => tbl.operationKey.equals(record.operationKey)))
          .getSingle();
      expect(outbox.status, equals(OutboxStatus.blocked.value));
    });

    testWidgets('Failure Validation: Cryptographic AAD mismatch rejects forged record', (
      WidgetTester tester,
    ) async {
      final encryptionService = getIt<IEncryptionService>();

      // Encrypt with Learner A context
      final encrypted = await encryptionService.encrypt(
        plainText: '{"q1":"opt_a"}',
        associatedData:
            '{"learnerId":"learner-a","lessonId":"lesson_1","operationKey":"op_1","revisionId":"rev_1"}',
      );

      // Attempt to decrypt with Learner B context (tampered AAD)
      expect(
        () async => await encryptionService.decrypt(
          cipherText: encrypted,
          associatedData:
              '{"learnerId":"learner-b","lessonId":"lesson_1","operationKey":"op_1","revisionId":"rev_1"}',
        ),
        throwsA(isA<SecurityException>()),
      );
    });
  });
}
