import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:toga_assessment/core/database/app_database.dart';
import 'package:toga_assessment/core/security/encryption_service.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';
import 'package:toga_assessment/core/security/session_manager.dart';
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
  late AppDatabase database;
  late ISecureStorage secureStorage;
  late IEncryptionService encryptionService;
  late SessionManager sessionManager;
  late QuizLocalDataSource localDataSource;
  late QuizFixtureDataSource fixtureDataSource;
  late QuizRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    secureStorage = InMemorySecureStorage();
    encryptionService = AesGcmEncryptionService(secureStorage: secureStorage);
    sessionManager = SessionManager(secureStorage: secureStorage);

    localDataSource = QuizLocalDataSource(
      database: database,
      encryptionService: encryptionService,
    );
    fixtureDataSource = QuizFixtureDataSource();

    repository = QuizRepositoryImpl(
      localDataSource: localDataSource,
      fixtureDataSource: fixtureDataSource,
      sessionManager: sessionManager,
    );

    // Default to Learner A session
    await sessionManager.setSession(
      learnerId: 'learner-a',
      accessToken: 'token_a',
      refreshToken: 'refresh_a',
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('QuizRepositoryImpl & Atomic Encrypted Drafts', () {
    test(
      'saves answer with encryption and retrieves decrypted answer',
      () async {
        await repository.saveAnswer(
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
          questionId: 'q1',
          optionId: 'opt_1c',
          currentQuestionIndex: 0,
        );

        final draft = await repository.getDraft('provisional_lesson_1');
        expect(draft, isNotNull);
        expect(draft!.learnerId, equals('learner-a'));
        expect(draft.answers['q1'], equals('opt_1c'));

        // Verify that option in raw SQLite is encrypted and NOT plaintext
        final rawAnswers = await database.select(database.quizAnswers).get();
        expect(rawAnswers.length, 1);
        expect(
          rawAnswers.first.encryptedSelectedOptionId,
          isNot(equals('opt_1c')),
        );
      },
    );

    test(
      'Learner isolation: Learner A and Learner B drafts remain completely separate',
      () async {
        // 1. Learner A answers Q1 with opt_1c
        await repository.saveAnswer(
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
          questionId: 'q1',
          optionId: 'opt_1c',
          currentQuestionIndex: 0,
        );

        // 2. Switch session to Learner B
        await sessionManager.setSession(
          learnerId: 'learner-b',
          accessToken: 'token_b',
          refreshToken: 'refresh_b',
        );

        // Verify Learner B has NO draft yet
        final draftBInitial = await repository.getDraft('provisional_lesson_1');
        expect(draftBInitial, isNull);

        // 3. Learner B answers Q1 with opt_1a
        await repository.saveAnswer(
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
          questionId: 'q1',
          optionId: 'opt_1a',
          currentQuestionIndex: 0,
        );

        final draftB = await repository.getDraft('provisional_lesson_1');
        expect(draftB!.learnerId, equals('learner-b'));
        expect(draftB.answers['q1'], equals('opt_1a'));

        // 4. Switch back to Learner A: verify Learner A's draft is untouched
        await sessionManager.setSession(
          learnerId: 'learner-a',
          accessToken: 'token_a',
          refreshToken: 'refresh_a',
        );

        final draftA = await repository.getDraft('provisional_lesson_1');
        expect(draftA!.learnerId, equals('learner-a'));
        expect(draftA.answers['q1'], equals('opt_1c'));
      },
    );

    test(
      'Process termination and recovery: restores exact answers, position and revision',
      () async {
        // Step 1-6: Answer Q1, Answer Q2, navigate to Q3
        await repository.saveAnswer(
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
          questionId: 'q1',
          optionId: 'opt_1c',
          currentQuestionIndex: 0,
        );
        await repository.saveAnswer(
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
          questionId: 'q2',
          optionId: 'opt_2b',
          currentQuestionIndex: 1,
        );
        await repository.updatePosition(
          lessonId: 'provisional_lesson_1',
          currentQuestionIndex: 2, // Position Q3
        );

        // Step 7-9: Simulate process restart by recreating repository with same database and session
        final newRepository = QuizRepositoryImpl(
          localDataSource: localDataSource,
          fixtureDataSource: fixtureDataSource,
          sessionManager: sessionManager,
        );

        // Step 10-11: Restore draft and verify state
        final restored = await newRepository.getDraft('provisional_lesson_1');
        expect(restored, isNotNull);
        expect(restored!.revisionId, equals('rev_1_0'));
        expect(restored.currentQuestionIndex, equals(2));
        expect(restored.answers['q1'], equals('opt_1c'));
        expect(restored.answers['q2'], equals('opt_2b'));
      },
    );

    test('Revision pinning matches current revision', () async {
      final isCurrent = await repository.isRevisionCurrent(
        lessonId: 'provisional_lesson_1',
        draftRevisionId: 'rev_1_0',
      );
      expect(isCurrent, isTrue);

      final isStale = await repository.isRevisionCurrent(
        lessonId: 'provisional_lesson_1',
        draftRevisionId: 'rev_0_9_old',
      );
      expect(isStale, isFalse);
    });
  });
}
