import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:toga_assessment/core/database/app_database.dart';
import 'package:toga_assessment/core/security/encryption_service.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';
import 'package:toga_assessment/features/migration/data/datasources/legacy_migration_source.dart';
import 'package:toga_assessment/features/migration/data/services/legacy_migration_service.dart';
import 'package:toga_assessment/features/migration/domain/entities/migration_result.dart';
import 'package:toga_assessment/features/quiz/data/datasources/quiz_fixture_datasource.dart';
import 'package:toga_assessment/features/quiz/data/datasources/quiz_local_datasource.dart';

class InMemorySecureStorage implements ISecureStorage {
  final Map<String, String> _map = {};
  bool simulateFailure = false;

  @override
  Future<bool> containsKey(String key) async => _map.containsKey(key);

  @override
  Future<void> delete(String key) async => _map.remove(key);

  @override
  Future<void> deleteAll() async => _map.clear();

  @override
  Future<String?> read(String key) async {
    if (simulateFailure) throw Exception('Secure storage unavailable');
    return _map[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (simulateFailure) throw Exception('Secure storage write failure');
    _map[key] = value;
  }
}

class CrashingOnDeleteMigrationSource implements ILegacyMigrationSource {
  String? data;
  bool throwOnDelete = true;
  bool deleteWasAttempted = false;

  CrashingOnDeleteMigrationSource(this.data);

  @override
  Future<String?> readRawLegacyData() async => data;

  @override
  Future<void> deleteLegacyData() async {
    deleteWasAttempted = true;
    if (throwOnDelete) {
      throw const FileSystemException('Simulated crash during file deletion');
    }
    data = null;
  }
}

void main() {
  const officialLegacyJson = '''
{
  "notice": "Insecure legacy seed for migration tests only. Do not adopt as your storage design.",
  "storage": "ordinary_preferences",
  "schema_version": 1,
  "refresh_token": "SYNTHETIC_A_REFRESH_1",
  "draft": {
    "owner": "learner_a",
    "lesson_id": "lesson-units",
    "content_revision": 1,
    "position": 2,
    "answers": {
      "r1-u1": "1",
      "r1-u2": "0"
    }
  },
  "outbox": []
}
''';

  late AppDatabase database;
  late InMemorySecureStorage secureStorage;
  late AesGcmEncryptionService encryptionService;
  late QuizLocalDataSource quizLocalDataSource;
  late QuizFixtureDataSource quizFixtureDataSource;
  late InMemoryLegacyMigrationSource migrationSource;
  late LegacyMigrationService migrationService;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    secureStorage = InMemorySecureStorage();
    encryptionService = AesGcmEncryptionService(secureStorage: secureStorage);
    quizLocalDataSource = QuizLocalDataSource(
      database: database,
      encryptionService: encryptionService,
    );
    quizFixtureDataSource = QuizFixtureDataSource();
    migrationSource = InMemoryLegacyMigrationSource(officialLegacyJson);

    migrationService = LegacyMigrationService(
      source: migrationSource,
      quizLocalDataSource: quizLocalDataSource,
      quizFixtureDataSource: quizFixtureDataSource,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Scenario 11: Legacy Migration Service & Recovery Validation', () {
    // ------------------------------------------------------------------------
    // 1. Successful migration after reauthentication
    // ------------------------------------------------------------------------
    test(
      '1. Successful migration after reauthentication: decrypts into Drift and purges legacy file',
      () async {
        final result = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );

        expect(result.status, equals(MigrationStatus.success));
        expect(result.migratedLessonId, equals('lesson-units'));
        expect(result.migratedAnswersCount, equals(2));

        // Invariant: Plaintext legacy source removed after success
        expect(await migrationSource.readRawLegacyData(), isNull);

        // Verify encrypted draft in Drift
        final draft = await quizLocalDataSource.getDraft(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
        );
        expect(draft, isNotNull);
        expect(draft!.revisionId, equals('1'));
        expect(draft.currentQuestionIndex, equals(2));
        expect(draft.answers['r1-u1'], equals('1'));
        expect(draft.answers['r1-u2'], equals('0'));
      },
    );

    // ------------------------------------------------------------------------
    // 2. Same-owner validation
    // ------------------------------------------------------------------------
    test(
      '2. Same-owner validation: Matches authenticated learner to legacy draft owner',
      () async {
        final result = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(result.status, equals(MigrationStatus.success));
      },
    );

    // ------------------------------------------------------------------------
    // 3. Wrong authenticated learner
    // ------------------------------------------------------------------------
    test(
      '3. Wrong authenticated learner: Blocks migration when learner_b attempts to migrate learner_a record',
      () async {
        final result = await migrationService.migrate(
          authenticatedLearnerId: 'learner_b',
        );

        expect(result.status, equals(MigrationStatus.ownerMismatch));
        expect(result.message, contains('Tenant boundary violation'));

        // Plaintext legacy source retained
        expect(await migrationSource.readRawLegacyData(), isNotNull);

        // No data persisted in database
        final draftB = await quizLocalDataSource.getDraft(
          learnerId: 'learner_b',
          lessonId: 'lesson-units',
        );
        expect(draftB, isNull);

        final draftA = await quizLocalDataSource.getDraft(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
        );
        expect(draftA, isNull);
      },
    );

    // ------------------------------------------------------------------------
    // 4. Unauthenticated attempt
    // ------------------------------------------------------------------------
    test(
      '4. Unauthenticated attempt: Rejects when authenticatedLearnerId is null or empty',
      () async {
        final result = await migrationService.migrate(
          authenticatedLearnerId: null,
        );
        expect(result.status, equals(MigrationStatus.unauthenticated));

        final emptyResult = await migrationService.migrate(
          authenticatedLearnerId: '   ',
        );
        expect(emptyResult.status, equals(MigrationStatus.unauthenticated));

        expect(await migrationSource.readRawLegacyData(), isNotNull);
      },
    );

    // ------------------------------------------------------------------------
    // 5. Invalid lesson or revision
    // ------------------------------------------------------------------------
    test(
      '5. Invalid lesson or revision: Rejects unknown lesson or revision without persisting',
      () async {
        final invalidLessonJson = officialLegacyJson.replaceAll(
          '"lesson_id": "lesson-units"',
          '"lesson_id": "unknown-nonexistent-lesson"',
        );
        migrationSource.setData(invalidLessonJson);

        final result1 = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(result1.status, equals(MigrationStatus.validationFailed));
        expect(result1.message, contains('Unknown lesson_id'));

        final invalidRevJson = officialLegacyJson.replaceAll(
          '"content_revision": 1',
          '"content_revision": 999',
        );
        migrationSource.setData(invalidRevJson);

        final result2 = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(result2.status, equals(MigrationStatus.validationFailed));
        expect(result2.message, contains('Revision "999" not valid'));

        // Plaintext source retained
        expect(await migrationSource.readRawLegacyData(), isNotNull);
      },
    );

    // ------------------------------------------------------------------------
    // 6. Invalid question ID or answer option
    // ------------------------------------------------------------------------
    test(
      '6. Invalid question ID or option: Rejects corrupted questions/options without inventing answers',
      () async {
        final badQuestionJson = officialLegacyJson.replaceAll(
          '"r1-u1": "1"',
          '"r1-fake-question": "1"',
        );
        migrationSource.setData(badQuestionJson);

        final result1 = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(result1.status, equals(MigrationStatus.validationFailed));
        expect(
          result1.message,
          contains('Question "r1-fake-question" not found'),
        );

        final badOptionJson = officialLegacyJson.replaceAll(
          '"r1-u1": "1"',
          '"r1-u1": "option_999_invalid"',
        );
        migrationSource.setData(badOptionJson);

        final result2 = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(result2.status, equals(MigrationStatus.validationFailed));
        expect(
          result2.message,
          contains('Option "option_999_invalid" not valid'),
        );

        // Legacy source preserved
        expect(await migrationSource.readRawLegacyData(), isNotNull);
      },
    );

    // ------------------------------------------------------------------------
    // 7. Corrupt legacy JSON
    // ------------------------------------------------------------------------
    test('7. Corrupt legacy JSON: Handles malformed JSON gracefully', () async {
      migrationSource.setData('{ MALFORMED_JSON_CORRUPT: [[[ ');

      final result = await migrationService.migrate(
        authenticatedLearnerId: 'learner_a',
      );
      expect(result.status, equals(MigrationStatus.corruptedData));
      expect(await migrationSource.readRawLegacyData(), isNotNull);
    });

    // ------------------------------------------------------------------------
    // 8. Missing encryption key / storage failure
    // ------------------------------------------------------------------------
    test(
      '8. Missing encryption key: Retains plaintext legacy source when encryption fails',
      () async {
        secureStorage.simulateFailure = true;

        final result = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(result.status, equals(MigrationStatus.storageFailure));

        // Plaintext source MUST be retained and exactly match original content
        expect(await migrationSource.readRawLegacyData(), isNotNull);
        expect(
          await migrationSource.readRawLegacyData(),
          equals(officialLegacyJson),
        );

        // Invariant: Zero partial or unencrypted draft records created in database
        secureStorage.simulateFailure = false;
        final draft = await quizLocalDataSource.getDraft(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
        );
        expect(draft, isNull);
      },
    );

    // ------------------------------------------------------------------------
    // 9. Repeated migration idempotency
    // ------------------------------------------------------------------------
    test(
      '9. Repeated migration idempotency: Re-running does not duplicate or corrupt SQLite records',
      () async {
        // First run: success
        final result1 = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(result1.status, equals(MigrationStatus.success));

        // Second run: no data left in source
        final result2 = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(result2.status, equals(MigrationStatus.noDataFound));

        // Re-seed identical legacy data to test duplicate detection
        migrationSource.setData(officialLegacyJson);
        final result3 = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(result3.status, equals(MigrationStatus.alreadyMigrated));
        expect(await migrationSource.readRawLegacyData(), isNull);

        // Verify database still has exactly one draft
        final draft = await quizLocalDataSource.getDraft(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
        );
        expect(draft, isNotNull);
        expect(draft!.answers.length, equals(2));
      },
    );

    // ------------------------------------------------------------------------
    // 10. File-backed restart test (Restart during migration)
    // ------------------------------------------------------------------------
    test(
      '10. File-backed restart: Survives client DB closure and resumes without data loss',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'toga_migration_test_',
        );
        final legacyFile = File('${tempDir.path}/legacy_private_v1.json');
        final dbFile = File('${tempDir.path}/toga_app.sqlite');

        try {
          await legacyFile.writeAsString(officialLegacyJson);

          final fileSource = FileLegacyMigrationSource(legacyFile);
          final fileDb = AppDatabase(NativeDatabase(dbFile));
          final fileQuizLocal = QuizLocalDataSource(
            database: fileDb,
            encryptionService: encryptionService,
          );

          final service1 = LegacyMigrationService(
            source: fileSource,
            quizLocalDataSource: fileQuizLocal,
            quizFixtureDataSource: quizFixtureDataSource,
          );

          // Perform migration
          final result = await service1.migrate(
            authenticatedLearnerId: 'learner_a',
          );
          expect(result.status, equals(MigrationStatus.success));
          expect(legacyFile.existsSync(), isFalse);

          // Simulate client app restart
          await fileDb.close();

          // Relaunch app with restarted DB instance
          final restartedDb = AppDatabase(NativeDatabase(dbFile));
          final restartedQuizLocal = QuizLocalDataSource(
            database: restartedDb,
            encryptionService: encryptionService,
          );

          final migratedDraft = await restartedQuizLocal.getDraft(
            learnerId: 'learner_a',
            lessonId: 'lesson-units',
          );
          expect(migratedDraft, isNotNull);
          expect(migratedDraft!.answers['r1-u1'], equals('1'));
          expect(migratedDraft.answers['r1-u2'], equals('0'));

          await restartedDb.close();
        } finally {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      },
    );

    // ------------------------------------------------------------------------
    // 11. Interrupted migration recovery
    // ------------------------------------------------------------------------
    test(
      '11. Interrupted migration recovery: Failure mid-migration preserves legacy source; retry succeeds cleanly',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'toga_interrupted_mig_',
        );
        final legacyFile = File('${tempDir.path}/legacy_private_v1.json');
        final dbFile = File('${tempDir.path}/toga_app.sqlite');

        try {
          await legacyFile.writeAsString(officialLegacyJson);
          final fileSource = FileLegacyMigrationSource(legacyFile);
          final fileDb = AppDatabase(NativeDatabase(dbFile));

          // First attempt: simulate interruption by disabling encryption storage mid-flight
          secureStorage.simulateFailure = true;
          final fileQuizLocal1 = QuizLocalDataSource(
            database: fileDb,
            encryptionService: encryptionService,
          );
          final failingService = LegacyMigrationService(
            source: fileSource,
            quizLocalDataSource: fileQuizLocal1,
            quizFixtureDataSource: quizFixtureDataSource,
          );

          final failResult = await failingService.migrate(
            authenticatedLearnerId: 'learner_a',
          );
          expect(failResult.status, equals(MigrationStatus.storageFailure));

          // Invariant: Legacy file MUST still exist on disk with unchanged content
          expect(legacyFile.existsSync(), isTrue);
          expect(await legacyFile.readAsString(), equals(officialLegacyJson));

          // Second attempt: restore storage and re-run migration
          secureStorage.simulateFailure = false;
          final recoveredResult = await failingService.migrate(
            authenticatedLearnerId: 'learner_a',
          );
          expect(recoveredResult.status, equals(MigrationStatus.success));

          // Legacy file safely purged after successful second attempt
          expect(legacyFile.existsSync(), isFalse);

          // Verify draft in database
          final draft = await fileQuizLocal1.getDraft(
            learnerId: 'learner_a',
            lessonId: 'lesson-units',
          );
          expect(draft, isNotNull);
          expect(draft!.answers.length, equals(2));

          await fileDb.close();
        } finally {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      },
    );

    // ------------------------------------------------------------------------
    // 12. Invalid saved position validation
    // ------------------------------------------------------------------------
    test(
      '12. Invalid position: Rejects negative or out-of-bounds saved positions',
      () async {
        // Negative position (-1)
        final negativePosJson = officialLegacyJson.replaceAll(
          '"position": 2',
          '"position": -1',
        );
        migrationSource.setData(negativePosJson);

        final resultNegative = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(resultNegative.status, equals(MigrationStatus.validationFailed));
        expect(resultNegative.message, contains('Invalid saved position -1'));
        expect(await migrationSource.readRawLegacyData(), isNotNull);

        // Out of bounds position (99)
        final outOfBoundsPosJson = officialLegacyJson.replaceAll(
          '"position": 2',
          '"position": 99',
        );
        migrationSource.setData(outOfBoundsPosJson);

        final resultOutOfBounds = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(
          resultOutOfBounds.status,
          equals(MigrationStatus.validationFailed),
        );
        expect(
          resultOutOfBounds.message,
          contains('Invalid saved position 99'),
        );
        expect(await migrationSource.readRawLegacyData(), isNotNull);
      },
    );

    // ------------------------------------------------------------------------
    // 13. Active crash between encrypted persistence and plaintext deletion
    // ------------------------------------------------------------------------
    test(
      '13. Active crash between persistence and deletion: Exception during file deletion preserves file, resumed migration cleans up without duplicates',
      () async {
        final crashingSource = CrashingOnDeleteMigrationSource(
          officialLegacyJson,
        );
        final crashingService = LegacyMigrationService(
          source: crashingSource,
          quizLocalDataSource: quizLocalDataSource,
          quizFixtureDataSource: quizFixtureDataSource,
        );

        // 1. Run migration: DB transaction succeeds, but deleteLegacyData returns storageFailure (simulated crash)
        crashingSource.throwOnDelete = true;
        final crashResult = await crashingService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(crashResult.status, equals(MigrationStatus.storageFailure));
        expect(
          crashResult.message,
          contains('Encrypted persistence succeeded but plaintext deletion failed'),
        );

        // Verify state at the crash point:
        // A. Encrypted draft WAS safely committed to SQLite
        final draftAfterCrash = await quizLocalDataSource.getDraft(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
        );
        expect(draftAfterCrash, isNotNull);
        expect(draftAfterCrash!.answers['r1-u1'], equals('1'));

        // B. Plaintext legacy data is STILL present on disk (not lost or half-deleted)
        expect(await crashingSource.readRawLegacyData(), isNotNull);
        expect(
          await crashingSource.readRawLegacyData(),
          equals(officialLegacyJson),
        );

        // 2. Application relaunches: deletion now succeeds normally
        crashingSource.throwOnDelete = false;
        final recoveryResult = await crashingService.migrate(
          authenticatedLearnerId: 'learner_a',
        );

        // 3. Service detects alreadyMigrated, safely purges plaintext source
        expect(recoveryResult.status, equals(MigrationStatus.alreadyMigrated));
        expect(await crashingSource.readRawLegacyData(), isNull);

        // 4. Invariant: Database still has exactly one clean draft, zero duplicates
        final finalDraft = await quizLocalDataSource.getDraft(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
        );
        expect(finalDraft, isNotNull);
        expect(finalDraft!.answers.length, equals(2));
      },
    );

    // ------------------------------------------------------------------------
    // 14. Scenario 11 Corrupt local record variant
    // ------------------------------------------------------------------------
    test(
      '14. Scenario 11 Corrupt local record: Tampered ciphertext or corrupted SQLite answer does not crash and allows clean draft recovery',
      () async {
        // 1. Perform successful initial migration
        final migResult = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(migResult.status, equals(MigrationStatus.success));

        // 2. Corrupt a local SQLite answer row by overwriting it with invalid garbage ciphertext
        final draftId = 'learner_a_lesson-units';
        final answerId = '${draftId}_r1-u1';
        await database.customStatement(
          "UPDATE quiz_answers SET encrypted_selected_option_id = 'CORRUPTED_GARBAGE_PAYLOAD' WHERE id = '$answerId';",
        );

        // 3. Read draft via local datasource: must handle decryption failure gracefully without crashing
        final recoveredDraft = await quizLocalDataSource.getDraft(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
        );
        expect(recoveredDraft, isNotNull);
        // Invariant: Does NOT crash, does NOT invent answer; corrupted option is safely omitted
        expect(recoveredDraft!.answers.containsKey('r1-u1'), isFalse);
        expect(
          recoveredDraft.answers['r1-u2'],
          equals('0'),
        ); // Uncorrupted answer preserved

        // 4. Explicit recover/reset decision: learner can safely overwrite corrupted draft with valid answer
        await quizLocalDataSource.saveAnswerAtomically(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
          revisionId: '1',
          questionId: 'r1-u1',
          optionId: '1',
          currentQuestionIndex: 0,
        );

        final repairedDraft = await quizLocalDataSource.getDraft(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
        );
        expect(repairedDraft!.answers['r1-u1'], equals('1'));
        expect(repairedDraft.answers['r1-u2'], equals('0'));
      },
    );

    // ------------------------------------------------------------------------
    // 15. Scenario 11 Missing storage key variant
    // ------------------------------------------------------------------------
    test(
      '15. Scenario 11 Missing storage key: Erased or unavailable platform key fails cleanly, preserving plaintext legacy source',
      () async {
        // Clear secure storage completely
        await secureStorage.deleteAll();
        secureStorage.simulateFailure = true;

        final result = await migrationService.migrate(
          authenticatedLearnerId: 'learner_a',
        );
        expect(result.status, equals(MigrationStatus.storageFailure));

        // Invariant: Plaintext source is preserved for recovery when key is restored
        expect(await migrationSource.readRawLegacyData(), isNotNull);
        expect(
          await migrationSource.readRawLegacyData(),
          equals(officialLegacyJson),
        );

        // No corrupt records in database
        secureStorage.simulateFailure = false;
        final draft = await quizLocalDataSource.getDraft(
          learnerId: 'learner_a',
          lessonId: 'lesson-units',
        );
        expect(draft, isNull);
      },
    );
  });
}
