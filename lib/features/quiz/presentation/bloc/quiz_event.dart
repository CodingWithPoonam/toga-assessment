import 'package:equatable/equatable.dart';

abstract class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => [];
}

class StartQuiz extends QuizEvent {
  final String lessonId;
  final String revisionId;

  const StartQuiz({required this.lessonId, required this.revisionId});

  @override
  List<Object?> get props => [lessonId, revisionId];
}

class AnswerSelected extends QuizEvent {
  final String questionId;
  final String optionId;

  const AnswerSelected({required this.questionId, required this.optionId});

  @override
  List<Object?> get props => [questionId, optionId];
}

class NextQuestion extends QuizEvent {
  const NextQuestion();
}

class PreviousQuestion extends QuizEvent {
  const PreviousQuestion();
}

class JumpToQuestion extends QuizEvent {
  final int index;

  const JumpToQuestion(this.index);

  @override
  List<Object?> get props => [index];
}

class RevisionMismatchResolved extends QuizEvent {
  final bool resetDraft;

  const RevisionMismatchResolved({required this.resetDraft});

  @override
  List<Object?> get props => [resetDraft];
}
