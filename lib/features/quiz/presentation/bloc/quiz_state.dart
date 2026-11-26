import 'package:equatable/equatable.dart';
import '../../domain/entities/quiz_question.dart';

abstract class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {
  const QuizInitial();
}

class QuizLoading extends QuizState {
  const QuizLoading();
}

class QuizInProgress extends QuizState {
  final List<QuizQuestion> questions;
  final int currentIndex;
  final Map<String, String> answers;
  final String revisionId;
  final bool isSavedOffline;
  final bool isSaving;

  const QuizInProgress({
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.revisionId,
    this.isSavedOffline = false,
    this.isSaving = false,
  });

  QuizQuestion get currentQuestion => questions[currentIndex];

  int get totalQuestions => questions.length;

  int get answeredCount => answers.length;

  bool isQuestionAnswered(int index) =>
      answers.containsKey(questions[index].id);

  QuizInProgress copyWith({
    List<QuizQuestion>? questions,
    int? currentIndex,
    Map<String, String>? answers,
    String? revisionId,
    bool? isSavedOffline,
    bool? isSaving,
  }) {
    return QuizInProgress(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      revisionId: revisionId ?? this.revisionId,
      isSavedOffline: isSavedOffline ?? this.isSavedOffline,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [
    questions,
    currentIndex,
    answers,
    revisionId,
    isSavedOffline,
    isSaving,
  ];
}

class QuizRevisionMismatch extends QuizState {
  final String draftRevisionId;
  final String currentRevisionId;
  final QuizDraft draft;

  const QuizRevisionMismatch({
    required this.draftRevisionId,
    required this.currentRevisionId,
    required this.draft,
  });

  @override
  List<Object?> get props => [draftRevisionId, currentRevisionId, draft];
}

class QuizError extends QuizState {
  final String message;

  const QuizError(this.message);

  @override
  List<Object?> get props => [message];
}
