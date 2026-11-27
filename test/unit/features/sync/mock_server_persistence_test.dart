import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:toga_assessment/core/database/app_database.dart';
import 'package:toga_assessment/core/di/injection.dart';
import 'package:toga_assessment/core/network/api_exceptions.dart';
import 'package:toga_assessment/core/security/encryption_service.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';
import 'package:toga_assessment/core/security/session_manager.dart';
import 'package:toga_assessment/features/sync/data/datasources/sync_local_datasource.dart';
import 'package:toga_assessment/features/sync/data/datasources/sync_remote_datasource.dart';
import 'package:toga_assessment/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:toga_assessment/features/sync/domain/entities/outbox_enums.dart';
import 'package:toga_assessment/features/sync/domain/entities/submission_snapshot.dart';
import 'package:toga_assessment/features/sync/domain/entities/sync_result.dart';
import 'package:toga_assessment/features/sync/domain/usecases/sync_engine.dart';
import 'package:toga_assessment/features/quiz/data/datasources/quiz_fixture_datasource.dart';
import 'package:toga_assessment/features/quiz/data/datasources/quiz_local_datasource.dart';
import 'package:toga_assessment/features/quiz/data/repositories/quiz_repository_impl.dart';

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
  late Directory tempDir;
  late File serverStoreFile;
  late File clientDbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('toga_mock_server_test_');
    serverStoreFile = File('${tempDir.path}/mock_server_store.json');
    clientDbFile = File('${tempDir.path}/client_test_db.sqlite');
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Scenario 04 & Idempotency: Persistent Mock Server & Idempotency Rules', () {
    // ------------------------------------------------------------------------
    // 1. Same-key same-body replay
    // ------------------------------------------------------------------------
    test('1. Same-key same-body: 201 on first, 200 on second, identical ack, 1 record', () async {
      final store = FileMockServerStore(serverStoreFile);
      final server = SyncRemoteDataSource(
        simulatedLatency: Duration.zero,
        serverStore: store,
      );

      const opKey = 'op_key_idempotent_1';

      final snapshot = SubmissionSnapshot(
        operationKey: opKey,
        learnerId: 'learner_a',
        lessonId: 'lesson-units',
        revisionId: '1',
        answers: const {
          'r1-u1': '1',
          'r1-u2': '0',
          'r1-u3': '1',
          'r1-u4': '0',
          'r1-u5': '0',
        },
        stagedAt: DateTime.now(),
      );

      // First request: valid 201
      final firstResponse = await server.submitQuizAttempt(
        snapshot: snapshot,
        operationKey: opKey,
      );
      expect(firstResponse.httpStatusCode, equals(201));
      expect(firstResponse.isIdempotentDuplicate, isFalse);
      expect(firstResponse.status, equals('accepted'));
      expect(firstResponse.score, equals(5));
      expect(server.committedOperationsCount, equals(1));

      // Second request with same key and canonical body: 200 replay
      final secondResponse = await server.submitQuizAttempt(
        snapshot: snapshot,
        operationKey: opKey,
      );
      expect(secondResponse.httpStatusCode, equals(200));
      expect(secondResponse.isIdempotentDuplicate, isTrue);
      expect(secondResponse.submissionId, equals(firstResponse.submissionId));
      expect(secondResponse.score, equals(firstResponse.score));
      expect(secondResponse.acknowledgedAt, equals(firstResponse.acknowledgedAt));

      // Exactly one logical server submission persists
      expect(server.committedOperationsCount, equals(1));
    });

    // ------------------------------------------------------------------------
    // 2. Same-key changed-body conflict (409 IDEMPOTENCY_CONFLICT)
    // ------------------------------------------------------------------------
    test('2. Same-key changed-body: returns 409 IDEMPOTENCY_CONFLICT without overwriting original', () async {
      final store = FileMockServerStore(serverStoreFile);
      final server = SyncRemoteDataSource(
        simulatedLatency: Duration.zero,
        serverStore: store,
      );

      const opKey = 'op_conflict_key_1';

      final originalSnapshot = SubmissionSnapshot(
        operationKey: opKey,
        learnerId: 'learner_a',
        lessonId: 'lesson-units',
        revisionId: '1',
        answers: const {'r1-u1': '1', 'r1-u2': '0'},
        stagedAt: DateTime.now(),
      );

      // Commit original
      final originalAck = await server.submitQuizAttempt(
        snapshot: originalSnapshot,
        operationKey: opKey,
      );
      expect(originalAck.httpStatusCode, equals(201));

      // Attempt second submission with mutated answers under same key
      final mutatedSnapshot = SubmissionSnapshot(
        operationKey: opKey,
        learnerId: 'learner_a',
        lessonId: 'lesson-units',
        revisionId: '1',
        answers: const {'r1-u1': '0', 'r1-u2': '1'}, // Mutated answers!
        stagedAt: DateTime.now(),
      );

      expect(
        () async => await server.submitQuizAttempt(
          snapshot: mutatedSnapshot,
          operationKey: opKey,
        ),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.message,
            'message',
            contains('IDEMPOTENCY_CONFLICT'),
          ),
        ),
      );

      // Verify original record is unchanged
      final committed = server.getCommitted('learner_a', opKey);
      expect(committed, isNotNull);
      expect(committed!.response.submissionId, equals(originalAck.submissionId));
      expect(server.committedOperationsCount, equals(1));
    });

    // ------------------------------------------------------------------------
    // 3. Cross-owner idempotency isolation
    // ------------------------------------------------------------------------
    test('3. Cross-owner isolation: Learner A and B using identical operation key remain isolated', () async {
      final store = FileMockServerStore(serverStoreFile);
      final server = SyncRemoteDataSource(
        simulatedLatency: Duration.zero,
        serverStore: store,
      );

      const sharedKey = 'shared_op_key_abc';

      final snapshotA = SubmissionSnapshot(
        operationKey: sharedKey,
        learnerId: 'learner_a',
        lessonId: 'lesson-units',
        revisionId: '1',
        answers: const {'r1-u1': '1'},
        stagedAt: DateTime.now(),
      );

      final snapshotB = SubmissionSnapshot(
        operationKey: sharedKey,
        learnerId: 'learner_b',
        lessonId: 'lesson-units',
        revisionId: '1',
        answers: const {'r1-u1': '0'},
        stagedAt: DateTime.now(),
      );

      final ackA = await server.submitQuizAttempt(
        snapshot: snapshotA,
        operationKey: sharedKey,
      );
      final ackB = await server.submitQuizAttempt(
        snapshot: snapshotB,
        operationKey: sharedKey,
      );

      expect(ackA.userId, equals('learner_a'));
      expect(ackB.userId, equals('learner_b'));
      expect(ackA.submissionId, isNot(equals(ackB.submissionId)));
      expect(server.committedOperationsCount, equals(2));

      // Learner B cannot retrieve Learner A's acknowledgement
      final committedA = server.getCommitted('learner_a', sharedKey);
      final committedB = server.getCommitted('learner_b', sharedKey);
      expect(committedA!.response.userId, equals('learner_a'));
      expect(committedB!.response.userId, equals('learner_b'));
    });

    // ------------------------------------------------------------------------
    // 4. Reconcile-before-stale sequence
    // ------------------------------------------------------------------------
    test('4. Reconcile-before-stale: Committed rev 1 reconciles after server bumps to rev 2; new rev 1 rejected', () async {
      final store = FileMockServerStore(serverStoreFile);
      final server = SyncRemoteDataSource(
        simulatedLatency: Duration.zero,
        serverStore: store,
      );

      const opKey = 'op_reconcile_1';

      final rev1Snapshot = SubmissionSnapshot(
        operationKey: opKey,
        learnerId: 'learner_a',
        lessonId: 'lesson-units',
        revisionId: '1',
        answers: const {'r1-u1': '1', 'r1-u2': '0'},
        stagedAt: DateTime.now(),
      );

      // Step 1 & 2: Server commits submission, but response drops (Step 3)
      server.simulateCommitWithLostResponse = true;
      expect(
        () async => await server.submitQuizAttempt(
          snapshot: rev1Snapshot,
          operationKey: opKey,
        ),
        throwsA(isA<NoInternetException>()),
      );

      // Step 4: Server's active revision for lesson-units bumps to revision 2!
      server.currentLessonRevisions['lesson-units'] = '2';

      // Step 5: Client retries original rev 1 request with same key and body
      final replayedAck = await server.submitQuizAttempt(
        snapshot: rev1Snapshot,
        operationKey: opKey,
      );

      // Step 6: Server returns original acknowledgement (HTTP 200) rather than STALE_CONTENT!
      expect(replayedAck.httpStatusCode, equals(200));
      expect(replayedAck.isIdempotentDuplicate, isTrue);
      expect(replayedAck.operationKey, equals(opKey));
      expect(replayedAck.revisionId, equals('1'));

      // Step 7: A brand-new unaccepted rev 1 submission with a different operation key MUST be rejected with STALE_CONTENT
      final newRev1Snapshot = SubmissionSnapshot(
        operationKey: 'new_op_key_uncommitted',
        learnerId: 'learner_a',
        lessonId: 'lesson-units',
        revisionId: '1',
        answers: const {'r1-u1': '1'},
        stagedAt: DateTime.now(),
      );

      expect(
        () async => await server.submitQuizAttempt(
          snapshot: newRev1Snapshot,
          operationKey: 'new_op_key_uncommitted',
        ),
        throwsA(
          isA<ConflictException>().having(
            (e) => e.message,
            'message',
            contains('STALE_CONTENT'),
          ),
        ),
      );
    });

    // ------------------------------------------------------------------------
    // 5. Genuine server datasource recreation from disk
    // ------------------------------------------------------------------------
    test('5. Server recreation: Destroying and recreating SyncRemoteDataSource recovers disk-persisted state', () async {
      const opKey = 'persist_recreate_key_1';
      final snapshot = SubmissionSnapshot(
        operationKey: opKey,
        learnerId: 'learner_a',
        lessonId: 'lesson-units',
        revisionId: '1',
        answers: const {'r1-u1': '1'},
        stagedAt: DateTime.now(),
      );

      // 1. Initial instance commits submission
      SyncRemoteDataSource? server1 = SyncRemoteDataSource(
        simulatedLatency: Duration.zero,
        persistentStorageFile: serverStoreFile,
      );

      final initialAck = await server1.submitQuizAttempt(
        snapshot: snapshot,
        operationKey: opKey,
      );
      expect(initialAck.httpStatusCode, equals(201));

      // Verify file exists on disk and is valid JSON
      expect(serverStoreFile.existsSync(), isTrue);
      final fileContent = serverStoreFile.readAsStringSync();
      expect(fileContent, contains(opKey));
      expect(fileContent, contains(initialAck.submissionId));

      // 2. Kill the first server instance
      server1 = null;

      // 3. Create a completely new SyncRemoteDataSource instance pointing to the same file
      final server2 = SyncRemoteDataSource(
        simulatedLatency: Duration.zero,
        persistentStorageFile: serverStoreFile,
      );

      expect(server2.committedOperationsCount, equals(1));
      expect(server2.hasCommitted('learner_a', opKey), isTrue);

      // 4. Replay submission on second server instance: recovers original acknowledgement
      final replayAck = await server2.submitQuizAttempt(
        snapshot: snapshot,
        operationKey: opKey,
      );

      expect(replayAck.httpStatusCode, equals(200));
      expect(replayAck.isIdempotentDuplicate, isTrue);
      expect(replayAck.submissionId, equals(initialAck.submissionId));
      expect(replayAck.acknowledgedAt, equals(initialAck.acknowledgedAt));
    });

    // ------------------------------------------------------------------------
    // 6. Complete Client & Server Restart (Scenario 04 End-to-End)
    // ------------------------------------------------------------------------
    test('6. Scenario 04 E2E: Client process crash and server datasource recreation reconciles lost response', () async {
      final secureStorage = InMemorySecureStorage();
      final sessionManager = SessionManager(secureStorage: secureStorage);
      final encryptionService = AesGcmEncryptionService(secureStorage: secureStorage);
      var database = AppDatabase(NativeDatabase(clientDbFile));

      await sessionManager.setSession(
        learnerId: 'learner_a',
        accessToken: 'mem_token_a',
        refreshToken: 'sec_token_a',
      );

      final quizLocal = QuizLocalDataSource(
        database: database,
        encryptionService: encryptionService,
      );
      final quizRepo = QuizRepositoryImpl(
        localDataSource: quizLocal,
        fixtureDataSource: QuizFixtureDataSource(),
        sessionManager: sessionManager,
      );

      final syncLocal = SyncLocalDataSource(
        database: database,
        encryptionService: encryptionService,
      );
      final syncRepo = SyncRepositoryImpl(
        localDataSource: syncLocal,
        sessionManager: sessionManager,
      );

      // 1. Initial persistent server datasource
      var serverDataSource = SyncRemoteDataSource(
        simulatedLatency: Duration.zero,
        persistentStorageFile: serverStoreFile,
      );

      var syncEngine = SyncEngine(
        syncRepository: syncRepo,
        remoteDataSource: serverDataSource,
        encryptionService: encryptionService,
        sessionManager: sessionManager,
      );

      // 2. Save 5 answers
      for (int i = 1; i <= 5; i++) {
        await quizRepo.saveAnswer(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
          revisionId: '1',
          questionId: 'r1-u$i',
          optionId: '1',
          currentQuestionIndex: i - 1,
        );
      }

      // 3. Stage submission
      final staged = await syncRepo.stageSubmission(
        learnerId: 'learner_a',
        lessonId: 'lesson-units',
      );
      final initialOperationKey = staged.operationKey;

      // 4. Server commits submission, but response drops
      serverDataSource.simulateCommitWithLostResponse = true;

      final firstResult = await syncEngine.synchronize(learnerId: 'learner_a');
      expect(firstResult.outcome, equals(SyncOutcomeStatus.transientFailure));

      // 5. SIMULATE HARD PROCESS TERMINATION
      // Close client DB, reset GetIt, drop server datasource
      await database.close();
      await getIt.reset();

      // 6. RELAUNCH APP & RECREATE SERVER DATASOURCE
      final restartedDb = AppDatabase(NativeDatabase(clientDbFile));
      final restartedServerSource = SyncRemoteDataSource(
        simulatedLatency: Duration.zero,
        persistentStorageFile: serverStoreFile,
      );

      final restartedSyncLocal = SyncLocalDataSource(
        database: restartedDb,
        encryptionService: encryptionService,
      );
      final restartedSyncRepo = SyncRepositoryImpl(
        localDataSource: restartedSyncLocal,
        sessionManager: sessionManager,
      );

      final restartedSyncEngine = SyncEngine(
        syncRepository: restartedSyncRepo,
        remoteDataSource: restartedServerSource,
        encryptionService: encryptionService,
        sessionManager: sessionManager,
      );

      // Allow backoff window to elapse
      await Future<void>.delayed(const Duration(seconds: 2));

      // 7. Retry sync after relaunch: server reconciles and returns original committed receipt
      final retryResult = await restartedSyncEngine.synchronize(learnerId: 'learner_a');
      expect(retryResult.outcome, equals(SyncOutcomeStatus.success));
      expect(retryResult.operationKey, equals(initialOperationKey));

      // Verify outbox completed in client DB
      final outboxRecord = await restartedSyncRepo.getOutboxByOperationKey(initialOperationKey);
      expect(outboxRecord!.status, equals(OutboxStatus.completed));
      expect(outboxRecord.serverAcknowledgement, isNotNull);
      expect(outboxRecord.serverAcknowledgement, contains('accepted'));

      // Clean up restarted database
      await restartedDb.close();
    });

    // ------------------------------------------------------------------------
    // 7. Server store corruption handling
    // ------------------------------------------------------------------------
    test('7. Storage resilience: Handles corrupted JSON store gracefully or throws explicit error', () async {
      // Write corrupted non-JSON data
      serverStoreFile.writeAsStringSync('MALFORMED_NON_JSON_CORRUPT{{{');

      // Graceful fallback mode
      final resilientStore = FileMockServerStore(serverStoreFile, throwOnCorruption: false);
      expect(resilientStore.loadCommittedSubmissions(), isEmpty);

      // Strict exception mode
      final strictStore = FileMockServerStore(serverStoreFile, throwOnCorruption: true);
      expect(
        () => strictStore.loadCommittedSubmissions(),
        throwsA(isA<ServerStoreException>()),
      );
    });
  });
}
