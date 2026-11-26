import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/session_manager.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_fixture_datasource.dart';
import '../datasources/quiz_local_datasource.dart';

/// Repository managing quiz questions and learner-isolated encrypted drafts
class QuizRepositoryImpl implements QuizRepository {
  final QuizLocalDataSource localDataSource;
  final QuizFixtureDataSource fixtureDataSource;
  final ISessionManager sessionManager;

  QuizRepositoryImpl({
    required this.localDataSource,
    required this.fixtureDataSource,
    required this.sessionManager,
  });

  String _getVerifiedLearnerId() {
    final learnerId = sessionManager.activeLearnerId;
    if (learnerId == null || learnerId.isEmpty) {
      throw const SecurityException(
        'Unverified learner session: activeLearnerId is null',
      );
    }
    return learnerId;
  }

  @override
  Future<List<QuizQuestion>> getQuestionsForLesson(String lessonId) async {
    final questions = await fixtureDataSource.getQuestionsForLesson(lessonId);
    if (questions.isEmpty) {
      throw const ServerFailure('No questions found for the specified lesson');
    }
    return questions;
  }

  @override
  Future<QuizDraft?> getDraft(String lessonId) async {
    final learnerId = _getVerifiedLearnerId();
    return localDataSource.getDraft(learnerId: learnerId, lessonId: lessonId);
  }

  @override
  Future<void> saveAnswer({
    required String lessonId,
    required String revisionId,
    required String questionId,
    required String optionId,
    required int currentQuestionIndex,
  }) async {
    final learnerId = _getVerifiedLearnerId();
    await localDataSource.saveAnswerAtomically(
      learnerId: learnerId,
      lessonId: lessonId,
      revisionId: revisionId,
      questionId: questionId,
      optionId: optionId,
      currentQuestionIndex: currentQuestionIndex,
    );
  }

  @override
  Future<void> updatePosition({
    required String lessonId,
    required int currentQuestionIndex,
  }) async {
    final learnerId = _getVerifiedLearnerId();
    await localDataSource.updatePosition(
      learnerId: learnerId,
      lessonId: lessonId,
      currentQuestionIndex: currentQuestionIndex,
    );
  }

  @override
  Future<void> clearDraft(String lessonId) async {
    final learnerId = _getVerifiedLearnerId();
    await localDataSource.clearDraft(learnerId: learnerId, lessonId: lessonId);
  }

  @override
  Future<bool> isRevisionCurrent({
    required String lessonId,
    required String draftRevisionId,
  }) async {
    final questions = await getQuestionsForLesson(lessonId);
    if (questions.isEmpty) return true;
    final currentRevision = questions.first.revisionId;
    return currentRevision == draftRevisionId;
  }
}
