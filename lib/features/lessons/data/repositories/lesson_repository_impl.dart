import '../../../../core/errors/failures.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../datasources/lesson_fixture_datasource.dart';
import '../datasources/lesson_local_datasource.dart';
import '../models/lesson_model.dart';

/// Repository orchestrating lesson caching and offline fallback
class LessonRepositoryImpl implements LessonRepository {
  final LessonLocalDataSource localDataSource;
  final LessonFixtureDataSource fixtureDataSource;

  LessonRepositoryImpl({
    required this.localDataSource,
    required this.fixtureDataSource,
  });

  @override
  Future<List<Lesson>> getLessons({bool forceRefresh = false}) async {
    try {
      // 1. Fetch remote / fixture lessons
      final remoteLessons = await fixtureDataSource.fetchLessons();

      // 2. Cross-reference with durable SQLite cache
      final List<Lesson> result = [];
      for (final remote in remoteLessons) {
        final isCached = await localDataSource.isLessonCached(remote.id);
        result.add(remote.copyWith(isCached: isCached));
      }
      return result;
    } catch (_) {
      // Offline fallback: load from Drift SQLite
      final cached = await localDataSource.getCachedLessons();
      if (cached.isNotEmpty) {
        return cached;
      }
      throw const NetworkFailure(
        'Unable to load lessons offline. No cached content found.',
      );
    }
  }

  @override
  Future<Lesson> getLessonById(String lessonId) async {
    // 1. Check local durable cache first
    final cached = await localDataSource.getCachedLessonById(lessonId);
    if (cached != null) {
      return cached;
    }

    // 2. Fetch from fixture / remote
    final remote = await fixtureDataSource.fetchLessonById(lessonId);
    if (remote != null) {
      // Cache immediately upon successful fetch to ensure offline study
      await cacheLesson(remote);
      return remote.copyWith(isCached: true);
    }

    throw ServerFailure('Lesson not found with ID $lessonId');
  }

  @override
  Future<void> cacheLesson(Lesson lesson) async {
    final model = LessonModel(
      id: lesson.id,
      revisionId: lesson.revisionId,
      title: lesson.title,
      summary: lesson.summary,
      content: lesson.content,
      isCached: true,
      cachedAt: DateTime.now(),
    );
    await localDataSource.cacheLesson(model);
  }

  @override
  Future<bool> isLessonCached(String lessonId) {
    return localDataSource.isLessonCached(lessonId);
  }
}
