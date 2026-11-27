import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart' hide QuizDraft;
import '../../../../core/security/encryption_service.dart';
import '../../domain/entities/quiz_question.dart';

/// Local data source persisting quiz drafts and encrypted question answers
class QuizLocalDataSource {
  final AppDatabase database;
  final IEncryptionService encryptionService;

  QuizLocalDataSource({
    required this.database,
    required this.encryptionService,
  });

  /// Reads a draft and decrypts individual stored answers
  Future<QuizDraft?> getDraft({
    required String learnerId,
    required String lessonId,
  }) async {
    final draftQuery = database.select(database.quizDrafts)
      ..where(
        (tbl) =>
            tbl.learnerId.equals(learnerId) & tbl.lessonId.equals(lessonId),
      );
    final draftRow = await draftQuery.getSingleOrNull();

    if (draftRow == null) return null;

    final answersQuery = database.select(database.quizAnswers)
      ..where((tbl) => tbl.draftId.equals(draftRow.id));
    final answerRows = await answersQuery.get();

    final Map<String, String> decryptedAnswers = {};
    for (final row in answerRows) {
      try {
        final aad =
            '$learnerId:${draftRow.lessonId}:${draftRow.revisionId}:${row.questionId}';
        final decryptedOption = await encryptionService.decrypt(
          cipherText: row.encryptedSelectedOptionId,
          associatedData: aad,
        );
        decryptedAnswers[row.questionId] = decryptedOption;
      } catch (_) {
        // Corrupted or tampered answer payload: discard corrupted option rather than crash
      }
    }

    return QuizDraft(
      id: draftRow.id,
      learnerId: draftRow.learnerId,
      lessonId: draftRow.lessonId,
      revisionId: draftRow.revisionId,
      currentQuestionIndex: draftRow.currentQuestionIndex,
      answers: decryptedAnswers,
      isSubmitted: draftRow.isSubmitted,
      updatedAt: draftRow.updatedAt,
    );
  }

  /// Atomically commits draft metadata and encrypted answer changes in a transaction
  Future<void> saveAnswerAtomically({
    required String learnerId,
    required String lessonId,
    required String revisionId,
    required String questionId,
    required String optionId,
    required int currentQuestionIndex,
  }) async {
    final draftId = '${learnerId}_$lessonId';
    final aad = '$learnerId:$lessonId:$revisionId:$questionId';
    final encryptedOption = await encryptionService.encrypt(
      plainText: optionId,
      associatedData: aad,
    );
    final now = DateTime.now();

    await database.transaction(() async {
      // 1. Insert or update the parent QuizDraft
      await database
          .into(database.quizDrafts)
          .insertOnConflictUpdate(
            QuizDraftsCompanion(
              id: Value(draftId),
              learnerId: Value(learnerId),
              lessonId: Value(lessonId),
              revisionId: Value(revisionId),
              currentQuestionIndex: Value(currentQuestionIndex),
              isSubmitted: const Value(false),
              updatedAt: Value(now),
            ),
          );

      // 2. Insert or update the encrypted QuizAnswer
      final answerId = '${draftId}_$questionId';
      await database
          .into(database.quizAnswers)
          .insertOnConflictUpdate(
            QuizAnswersCompanion(
              id: Value(answerId),
              draftId: Value(draftId),
              questionId: Value(questionId),
              encryptedSelectedOptionId: Value(encryptedOption),
              updatedAt: Value(now),
            ),
          );
    });
  }

  /// Atomically commits an entire quiz draft and batch-encrypts all answers in a single transaction
  Future<void> saveDraftAtomically({
    required String learnerId,
    required String lessonId,
    required String revisionId,
    required int currentQuestionIndex,
    required Map<String, String> answers,
  }) async {
    final draftId = '${learnerId}_$lessonId';
    final now = DateTime.now();

    final encryptedAnswers = <String, String>{};
    for (final entry in answers.entries) {
      final aad = '$learnerId:$lessonId:$revisionId:${entry.key}';
      final encryptedOption = await encryptionService.encrypt(
        plainText: entry.value,
        associatedData: aad,
      );
      encryptedAnswers[entry.key] = encryptedOption;
    }

    await database.transaction(() async {
      await database
          .into(database.quizDrafts)
          .insertOnConflictUpdate(
            QuizDraftsCompanion(
              id: Value(draftId),
              learnerId: Value(learnerId),
              lessonId: Value(lessonId),
              revisionId: Value(revisionId),
              currentQuestionIndex: Value(currentQuestionIndex),
              isSubmitted: const Value(false),
              updatedAt: Value(now),
            ),
          );

      for (final entry in encryptedAnswers.entries) {
        final answerId = '${draftId}_${entry.key}';
        await database
            .into(database.quizAnswers)
            .insertOnConflictUpdate(
              QuizAnswersCompanion(
                id: Value(answerId),
                draftId: Value(draftId),
                questionId: Value(entry.key),
                encryptedSelectedOptionId: Value(entry.value),
                updatedAt: Value(now),
              ),
            );
      }
    });
  }

  /// Updates question position without re-encrypting existing answers
  Future<void> updatePosition({
    required String learnerId,
    required String lessonId,
    required int currentQuestionIndex,
  }) async {
    final query = database.update(database.quizDrafts)
      ..where(
        (tbl) =>
            tbl.learnerId.equals(learnerId) & tbl.lessonId.equals(lessonId),
      );

    await query.write(
      QuizDraftsCompanion(
        currentQuestionIndex: Value(currentQuestionIndex),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Clears draft and cascades deletion to answers
  Future<void> clearDraft({
    required String learnerId,
    required String lessonId,
  }) async {
    final query = database.delete(database.quizDrafts)
      ..where(
        (tbl) =>
            tbl.learnerId.equals(learnerId) & tbl.lessonId.equals(lessonId),
      );
    await query.go();
  }
}
