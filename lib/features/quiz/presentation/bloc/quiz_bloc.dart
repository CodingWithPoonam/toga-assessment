import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

/// Manages interactive multiple-choice quiz workflow and atomic draft persistence
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final QuizRepository quizRepository;
  String? _activeLessonId;

  QuizBloc({required this.quizRepository}) : super(const QuizInitial()) {
    on<StartQuiz>(_onStartQuiz);
    on<AnswerSelected>(_onAnswerSelected);
    on<NextQuestion>(_onNextQuestion);
    on<PreviousQuestion>(_onPreviousQuestion);
    on<JumpToQuestion>(_onJumpToQuestion);
    on<RevisionMismatchResolved>(_onRevisionMismatchResolved);
  }

  Future<void> _onStartQuiz(StartQuiz event, Emitter<QuizState> emit) async {
    emit(const QuizLoading());
    _activeLessonId = event.lessonId;

    try {
      final questions = await quizRepository.getQuestionsForLesson(
        event.lessonId,
      );
      final existingDraft = await quizRepository.getDraft(event.lessonId);

      if (existingDraft != null) {
        // Revision check: if draft revision differs from current content revision, prompt learner
        if (existingDraft.revisionId != event.revisionId) {
          emit(
            QuizRevisionMismatch(
              draftRevisionId: existingDraft.revisionId,
              currentRevisionId: event.revisionId,
              draft: existingDraft,
            ),
          );
          return;
        }

        // Restore draft safely
        emit(
          QuizInProgress(
            questions: questions,
            currentIndex: existingDraft.currentQuestionIndex.clamp(
              0,
              questions.length - 1,
            ),
            answers: Map.from(existingDraft.answers),
            revisionId: existingDraft.revisionId,
            isSavedOffline: true,
          ),
        );
        return;
      }

      // Start fresh quiz
      emit(
        QuizInProgress(
          questions: questions,
          currentIndex: 0,
          answers: const {},
          revisionId: event.revisionId,
          isSavedOffline: false,
        ),
      );
    } catch (e) {
      emit(QuizError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onAnswerSelected(
    AnswerSelected event,
    Emitter<QuizState> emit,
  ) async {
    if (state is! QuizInProgress || _activeLessonId == null) return;
    final current = state as QuizInProgress;

    final updatedAnswers = Map<String, String>.from(current.answers)
      ..[event.questionId] = event.optionId;

    emit(current.copyWith(answers: updatedAnswers, isSaving: true));

    try {
      await quizRepository.saveAnswer(
        lessonId: _activeLessonId!,
        revisionId: current.revisionId,
        questionId: event.questionId,
        optionId: event.optionId,
        currentQuestionIndex: current.currentIndex,
      );
      emit(
        current.copyWith(
          answers: updatedAnswers,
          isSaving: false,
          isSavedOffline: true,
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          answers: updatedAnswers,
          isSaving: false,
          isSavedOffline: false,
        ),
      );
    }
  }

  Future<void> _onNextQuestion(
    NextQuestion event,
    Emitter<QuizState> emit,
  ) async {
    if (state is! QuizInProgress || _activeLessonId == null) return;
    final current = state as QuizInProgress;

    if (current.currentIndex < current.totalQuestions - 1) {
      final newIndex = current.currentIndex + 1;
      emit(current.copyWith(currentIndex: newIndex));
      await quizRepository.updatePosition(
        lessonId: _activeLessonId!,
        currentQuestionIndex: newIndex,
      );
    }
  }

  Future<void> _onPreviousQuestion(
    PreviousQuestion event,
    Emitter<QuizState> emit,
  ) async {
    if (state is! QuizInProgress || _activeLessonId == null) return;
    final current = state as QuizInProgress;

    if (current.currentIndex > 0) {
      final newIndex = current.currentIndex - 1;
      emit(current.copyWith(currentIndex: newIndex));
      await quizRepository.updatePosition(
        lessonId: _activeLessonId!,
        currentQuestionIndex: newIndex,
      );
    }
  }

  Future<void> _onJumpToQuestion(
    JumpToQuestion event,
    Emitter<QuizState> emit,
  ) async {
    if (state is! QuizInProgress || _activeLessonId == null) return;
    final current = state as QuizInProgress;

    if (event.index >= 0 && event.index < current.totalQuestions) {
      emit(current.copyWith(currentIndex: event.index));
      await quizRepository.updatePosition(
        lessonId: _activeLessonId!,
        currentQuestionIndex: event.index,
      );
    }
  }

  Future<void> _onRevisionMismatchResolved(
    RevisionMismatchResolved event,
    Emitter<QuizState> emit,
  ) async {
    if (state is! QuizRevisionMismatch || _activeLessonId == null) return;
    final mismatchState = state as QuizRevisionMismatch;

    emit(const QuizLoading());

    try {
      final questions = await quizRepository.getQuestionsForLesson(
        _activeLessonId!,
      );

      if (event.resetDraft) {
        // Discard old revision draft and start fresh
        await quizRepository.clearDraft(_activeLessonId!);
        emit(
          QuizInProgress(
            questions: questions,
            currentIndex: 0,
            answers: const {},
            revisionId: mismatchState.currentRevisionId,
            isSavedOffline: false,
          ),
        );
      } else {
        // Retain pinned revision draft as-is
        emit(
          QuizInProgress(
            questions: questions,
            currentIndex: mismatchState.draft.currentQuestionIndex.clamp(
              0,
              questions.length - 1,
            ),
            answers: Map.from(mismatchState.draft.answers),
            revisionId: mismatchState.draftRevisionId,
            isSavedOffline: true,
          ),
        );
      }
    } catch (e) {
      emit(QuizError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
