import '../entities/lesson.dart';

/// Contract for lesson content queries and durable offline caching
abstract class LessonRepository {
  Future<List<Lesson>> getLessons({bool forceRefresh = false});

  Future<Lesson> getLessonById(String lessonId);

  Future<Lesson?> getLessonByRevision({
    required String lessonId,
    required String revisionId,
  });

  Future<void> cacheLesson(Lesson lesson);

  Future<bool> isLessonCached(String lessonId);

  Future<bool> isRevisionCached({
    required String lessonId,
    required String revisionId,
  });
}
