import 'package:equatable/equatable.dart';

/// Domain entity representing a learning module with decoupled content revision tracking
class Lesson extends Equatable {
  final String id;
  final String revisionId;
  final String title;
  final String summary;
  final String content;
  final bool isCached;
  final DateTime? cachedAt;

  const Lesson({
    required this.id,
    required this.revisionId,
    required this.title,
    required this.summary,
    required this.content,
    this.isCached = false,
    this.cachedAt,
  });

  Lesson copyWith({
    String? id,
    String? revisionId,
    String? title,
    String? summary,
    String? content,
    bool? isCached,
    DateTime? cachedAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      revisionId: revisionId ?? this.revisionId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      isCached: isCached ?? this.isCached,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    revisionId,
    title,
    summary,
    content,
    isCached,
    cachedAt,
  ];
}
