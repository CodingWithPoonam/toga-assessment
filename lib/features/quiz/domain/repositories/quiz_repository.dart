import '../entities/quiz_question.dart';

/// Contract for quiz questions and atomic encrypted draft persistence
abstract class QuizRepository {
  Future<List<QuizQuestion>> getQuestionsForLesson(String lessonId);

  Future<QuizDraft?> getDraft(String lessonId);

  Future<void> saveAnswer({
    required String lessonId,
    required String revisionId,
    required String questionId,
    required String optionId,
    required int currentQuestionIndex,
  });

  Future<void> updatePosition({
    required String lessonId,
    required int currentQuestionIndex,
  });

  Future<void> clearDraft(String lessonId);

  Future<bool> isRevisionCurrent({
    required String lessonId,
    required String draftRevisionId,
  });
}
