import 'package:equatable/equatable.dart';

/// Represents a multiple-choice question option
class QuizOption extends Equatable {
  final String id;
  final String text;

  const QuizOption({required this.id, required this.text});

  @override
  List<Object?> get props => [id, text];
}

/// Domain entity representing a quiz question with decoupled revision identity
class QuizQuestion extends Equatable {
  final String id;
  final String text;
  final List<QuizOption> options;
  final String lessonId;
  final String revisionId;

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.lessonId,
    required this.revisionId,
  });

  @override
  List<Object?> get props => [id, text, options, lessonId, revisionId];
}

/// Represents an in-progress quiz draft pinned to a content revision
class QuizDraft extends Equatable {
  final String id;
  final String learnerId;
  final String lessonId;
  final String revisionId;
  final int currentQuestionIndex;
  final Map<String, String>
  answers; // questionId -> optionId (decrypted in memory)
  final bool isSubmitted;
  final DateTime updatedAt;

  const QuizDraft({
    required this.id,
    required this.learnerId,
    required this.lessonId,
    required this.revisionId,
    required this.currentQuestionIndex,
    required this.answers,
    this.isSubmitted = false,
    required this.updatedAt,
  });

  QuizDraft copyWith({
    String? id,
    String? learnerId,
    String? lessonId,
    String? revisionId,
    int? currentQuestionIndex,
    Map<String, String>? answers,
    bool? isSubmitted,
    DateTime? updatedAt,
  }) {
    return QuizDraft(
      id: id ?? this.id,
      learnerId: learnerId ?? this.learnerId,
      lessonId: lessonId ?? this.lessonId,
      revisionId: revisionId ?? this.revisionId,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    learnerId,
    lessonId,
    revisionId,
    currentQuestionIndex,
    answers,
    isSubmitted,
    updatedAt,
  ];
}
