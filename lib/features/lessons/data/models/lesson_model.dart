import '../../../../core/database/app_database.dart';
import '../../domain/entities/lesson.dart';

/// Model representing lesson data with JSON and Drift database mapping
class LessonModel extends Lesson {
  const LessonModel({
    required super.id,
    required super.revisionId,
    required super.title,
    required super.summary,
    required super.content,
    super.isCached = false,
    super.cachedAt,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      revisionId: json['revisionId'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String,
      isCached: json['isCached'] as bool? ?? false,
      cachedAt: json['cachedAt'] != null
          ? DateTime.parse(json['cachedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'revisionId': revisionId,
    'title': title,
    'summary': summary,
    'content': content,
    'isCached': isCached,
    'cachedAt': cachedAt?.toIso8601String(),
  };

  factory LessonModel.fromDrift(CachedLesson entry) {
    return LessonModel(
      id: entry.id,
      revisionId: entry.revisionId,
      title: entry.title,
      summary: entry.summary,
      content: entry.content,
      isCached: true,
      cachedAt: entry.cachedAt,
    );
  }

  CachedLessonsCompanion toCompanion() {
    return CachedLessonsCompanion.insert(
      id: id,
      revisionId: revisionId,
      title: title,
      summary: summary,
      content: content,
      cachedAt: cachedAt ?? DateTime.now(),
    );
  }
}
