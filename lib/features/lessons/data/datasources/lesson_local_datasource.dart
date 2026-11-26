import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../models/lesson_model.dart';

/// Local data source persisting lesson content into SQLite for durable offline study
class LessonLocalDataSource {
  final AppDatabase database;

  LessonLocalDataSource({required this.database});

  Future<void> cacheLesson(LessonModel lesson) async {
    await database
        .into(database.cachedLessons)
        .insertOnConflictUpdate(lesson.toCompanion());
  }

  Future<List<LessonModel>> getCachedLessons() async {
    final query = await database.select(database.cachedLessons).get();
    return query.map(LessonModel.fromDrift).toList();
  }

  Future<LessonModel?> getCachedLessonById(String lessonId) async {
    final query = database.select(database.cachedLessons)
      ..where((tbl) => tbl.id.equals(lessonId));
    final result = await query.getSingleOrNull();
    return result != null ? LessonModel.fromDrift(result) : null;
  }

  Future<LessonModel?> getLessonByRevision({
    required String lessonId,
    required String revisionId,
  }) async {
    final query = database.select(database.cachedLessons)
      ..where(
        (tbl) => tbl.id.equals(lessonId) & tbl.revisionId.equals(revisionId),
      );
    final result = await query.getSingleOrNull();
    return result != null ? LessonModel.fromDrift(result) : null;
  }

  Future<bool> isLessonCached(String lessonId) async {
    final lesson = await getCachedLessonById(lessonId);
    return lesson != null;
  }

  Future<bool> isRevisionCached({
    required String lessonId,
    required String revisionId,
  }) async {
    final lesson = await getLessonByRevision(
      lessonId: lessonId,
      revisionId: revisionId,
    );
    return lesson != null;
  }
}
