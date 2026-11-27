import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:toga_assessment/core/database/app_database.dart';
import 'package:toga_assessment/features/lessons/data/datasources/lesson_fixture_datasource.dart';
import 'package:toga_assessment/features/lessons/data/datasources/lesson_local_datasource.dart';
import 'package:toga_assessment/features/lessons/data/models/lesson_model.dart';
import 'package:toga_assessment/features/lessons/data/repositories/lesson_repository_impl.dart';

void main() {
  late AppDatabase database;
  late LessonLocalDataSource localDataSource;
  late LessonFixtureDataSource fixtureDataSource;
  late LessonRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    localDataSource = LessonLocalDataSource(database: database);
    fixtureDataSource = LessonFixtureDataSource(simulatedDelay: Duration.zero);
    repository = LessonRepositoryImpl(
      localDataSource: localDataSource,
      fixtureDataSource: fixtureDataSource,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('LessonRepositoryImpl', () {
    test('fetches lessons and reflects initial cache state', () async {
      final lessons = await repository.getLessons();
      expect(lessons.length, 2);
      expect(lessons.first.title, contains('Aviation'));
      expect(lessons.first.isCached, isFalse);
    });

    test('caches lesson and retrieves from local SQLite storage', () async {
      final lesson = await repository.getLessonById('provisional_lesson_1');
      expect(lesson.id, equals('provisional_lesson_1'));
      expect(lesson.isCached, isTrue);

      // Verify directly from local SQLite datasource
      final cached = await localDataSource.getCachedLessonById(
        'provisional_lesson_1',
      );
      expect(cached, isNotNull);
      expect(cached!.title, equals(lesson.title));
      expect(await repository.isLessonCached('provisional_lesson_1'), isTrue);
    });

    test('falls back to cached lessons when offline', () async {
      // 1. Prime cache
      await repository.getLessonById('provisional_lesson_1');

      // 2. Simulate offline environment by throwing in fixture source
      final throwingRepo = LessonRepositoryImpl(
        localDataSource: localDataSource,
        fixtureDataSource: _ThrowingFixtureDataSource(),
      );

      final lessons = await throwingRepo.getLessons();
      expect(lessons.isNotEmpty, isTrue);
      expect(lessons.first.id, equals('provisional_lesson_1'));
      expect(lessons.first.isCached, isTrue);
    });

    test('retrieves lesson by specific revision ID', () async {
      final lesson = await repository.getLessonByRevision(
        lessonId: 'provisional_lesson_1',
        revisionId: 'rev_1_0',
      );
      expect(lesson, isNotNull);
      expect(lesson!.revisionId, equals('rev_1_0'));
      expect(
        await repository.isRevisionCached(
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
        ),
        isTrue,
      );

      final nonExistent = await repository.getLessonByRevision(
        lessonId: 'provisional_lesson_1',
        revisionId: 'rev_9_9_unknown',
      );
      expect(nonExistent, isNull);
      expect(
        await repository.isRevisionCached(
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_9_9_unknown',
        ),
        isFalse,
      );
    });
  });
}

class _ThrowingFixtureDataSource extends LessonFixtureDataSource {
  @override
  Future<List<LessonModel>> fetchLessons() async {
    throw Exception('Simulated offline failure');
  }
}
