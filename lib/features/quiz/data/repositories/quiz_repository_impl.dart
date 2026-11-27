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

  void _validateLearnerSession(String learnerId) {
    final activeLearnerId = sessionManager.activeLearnerId;
    if (activeLearnerId == null || activeLearnerId.isEmpty) {
      throw const SecurityException(
        'Unverified learner session: activeLearnerId is null',
      );
    }
    if (activeLearnerId != learnerId) {
      throw SecurityException(
        'Tenant boundary violation: requested learnerId ($learnerId) does not match active session ($activeLearnerId)',
      );
    }
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
  Future<QuizDraft?> getDraft({
    required String learnerId,
    required String lessonId,
  }) async {
    _validateLearnerSession(learnerId);
    return localDataSource.getDraft(learnerId: learnerId, lessonId: lessonId);
  }

  @override
  Future<void> saveAnswer({
    required String learnerId,
    required String lessonId,
    required String revisionId,
    required String questionId,
    required String optionId,
    required int currentQuestionIndex,
  }) async {
    _validateLearnerSession(learnerId);
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
    required String learnerId,
    required String lessonId,
    required int currentQuestionIndex,
  }) async {
    _validateLearnerSession(learnerId);
    await localDataSource.updatePosition(
      learnerId: learnerId,
      lessonId: lessonId,
      currentQuestionIndex: currentQuestionIndex,
    );
  }

  @override
  Future<void> clearDraft({
    required String learnerId,
    required String lessonId,
  }) async {
    _validateLearnerSession(learnerId);
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
    return currentRevision == draftRevisionId ||
        (currentRevision == '1' && draftRevisionId == 'rev_1_0') ||
        (currentRevision == 'rev_1_0' && draftRevisionId == '1');
  }
}
