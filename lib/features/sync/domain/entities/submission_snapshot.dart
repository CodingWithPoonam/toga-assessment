import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Immutable snapshot of a learner's completed quiz attempt staged for synchronization
class SubmissionSnapshot extends Equatable {
  final String operationKey;
  final String learnerId;
  final String lessonId;
  final String revisionId;
  final Map<String, String> answers;
  final DateTime stagedAt;

  const SubmissionSnapshot({
    required this.operationKey,
    required this.learnerId,
    required this.lessonId,
    required this.revisionId,
    required this.answers,
    required this.stagedAt,
  });

  /// Constructs deterministic, canonical AAD with lexicographically sorted keys
  String buildCanonicalAad() {
    return jsonEncode({
      'learnerId': learnerId,
      'lessonId': lessonId,
      'operationKey': operationKey,
      'revisionId': revisionId,
    });
  }

  Map<String, dynamic> toJson() => {
    'operationKey': operationKey,
    'learnerId': learnerId,
    'lessonId': lessonId,
    'revisionId': revisionId,
    'answers': answers,
    'stagedAt': stagedAt.toIso8601String(),
  };

  factory SubmissionSnapshot.fromJson(Map<String, dynamic> json) =>
      SubmissionSnapshot(
        operationKey: json['operationKey'] as String,
        learnerId: json['learnerId'] as String,
        lessonId: json['lessonId'] as String,
        revisionId: json['revisionId'] as String,
        answers: Map<String, String>.from(json['answers'] as Map),
        stagedAt: DateTime.parse(json['stagedAt'] as String),
      );

  @override
  List<Object?> get props => [
    operationKey,
    learnerId,
    lessonId,
    revisionId,
    answers,
    stagedAt,
  ];
}
