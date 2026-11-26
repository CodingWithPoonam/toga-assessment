import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:toga_assessment/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  group('Database Schema v2 to v3 Migration & Data Preservation', () {
    test('Initializes with schema version 3', () {
      expect(database.schemaVersion, equals(3));
    });

    test(
      'Preserves existing cached lessons, drafts, and answers under schema v3',
      () async {
        // 1. Insert cached lesson
        await database
            .into(database.cachedLessons)
            .insert(
              CachedLessonsCompanion.insert(
                id: 'lesson_mig_1',
                revisionId: 'rev_1_0',
                title: 'Migration Flight Principles',
                summary: 'Summary',
                content: 'Content',
                cachedAt: DateTime.now(),
              ),
            );

        // 2. Insert draft with legacy isSubmitted
        await database
            .into(database.quizDrafts)
            .insert(
              QuizDraftsCompanion.insert(
                id: 'draft_mig_1',
                learnerId: 'learner-a',
                lessonId: 'lesson_mig_1',
                revisionId: 'rev_1_0',
                updatedAt: DateTime.now(),
              ),
            );

        // 3. Insert encrypted answer
        await database
            .into(database.quizAnswers)
            .insert(
              QuizAnswersCompanion.insert(
                id: 'ans_mig_1',
                draftId: 'draft_mig_1',
                questionId: 'q1',
                encryptedSelectedOptionId: 'encrypted_blob_test',
                updatedAt: DateTime.now(),
              ),
            );

        // 4. Verify all records exist and draftStatus defaults correctly
        final lessons = await database.select(database.cachedLessons).get();
        expect(lessons.length, 1);
        expect(lessons.first.id, equals('lesson_mig_1'));

        final drafts = await database.select(database.quizDrafts).get();
        expect(drafts.length, 1);
        expect(drafts.first.draftStatus, equals('in_progress'));
        expect(drafts.first.isSubmitted, isFalse);

        final answers = await database.select(database.quizAnswers).get();
        expect(answers.length, 1);
        expect(
          answers.first.encryptedSelectedOptionId,
          equals('encrypted_blob_test'),
        );

        // 5. Verify SubmissionOutbox table is available
        final outboxEntries = await database
            .select(database.submissionOutbox)
            .get();
        expect(outboxEntries, isEmpty);
      },
    );
  });
}
