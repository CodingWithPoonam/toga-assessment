import '../../domain/entities/quiz_question.dart';

/// Model representing quiz question with JSON serialization
class QuizQuestionModel extends QuizQuestion {
  const QuizQuestionModel({
    required super.id,
    required super.text,
    required super.options,
    required super.lessonId,
    required super.revisionId,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      lessonId: json['lessonId'] as String,
      revisionId: json['revisionId'] as String,
      options: (json['options'] as List<dynamic>)
          .map(
            (o) => QuizOption(id: o['id'] as String, text: o['text'] as String),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'lessonId': lessonId,
    'revisionId': revisionId,
    'options': options.map((o) => {'id': o.id, 'text': o.text}).toList(),
  };
}
