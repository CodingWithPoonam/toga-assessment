import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toga_assessment/features/lessons/domain/entities/lesson.dart';
import 'package:toga_assessment/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:toga_assessment/features/lessons/presentation/bloc/lesson_bloc.dart';
import 'package:toga_assessment/features/lessons/presentation/bloc/lesson_event.dart';
import 'package:toga_assessment/features/lessons/presentation/bloc/lesson_state.dart';

class MockLessonRepository extends Mock implements LessonRepository {}

void main() {
  late MockLessonRepository mockRepository;
  late LessonBloc bloc;

  const sampleLesson = Lesson(
    id: 'provisional_lesson_1',
    revisionId: 'rev_1_0',
    title: 'Aerodynamics',
    summary: 'Summary',
    content: 'Content',
    isCached: true,
  );

  setUp(() {
    mockRepository = MockLessonRepository();
    bloc = LessonBloc(lessonRepository: mockRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('LessonBloc', () {
    test('initial state is LessonInitial', () {
      expect(bloc.state, equals(const LessonInitial()));
    });

    blocTest<LessonBloc, LessonState>(
      'LoadLessons emits [LessonLoading, LessonSuccess] on success',
      build: () {
        when(
          () => mockRepository.getLessons(
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) async => [sampleLesson]);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadLessons()),
      expect: () => [
        const LessonLoading(),
        const LessonSuccess([sampleLesson], isOffline: true),
      ],
    );

    blocTest<LessonBloc, LessonState>(
      'LoadLessonDetail emits [LessonLoading, LessonDetailSuccess]',
      build: () {
        when(
          () => mockRepository.getLessonById('provisional_lesson_1'),
        ).thenAnswer((_) async => sampleLesson);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadLessonDetail('provisional_lesson_1')),
      expect: () => [
        const LessonLoading(),
        const LessonDetailSuccess(sampleLesson, isOffline: true),
      ],
    );

    blocTest<LessonBloc, LessonState>(
      'LoadLessons emits [LessonLoading, LessonEmpty] when list is empty',
      build: () {
        when(
          () => mockRepository.getLessons(
            forceRefresh: any(named: 'forceRefresh'),
          ),
        ).thenAnswer((_) async => []);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadLessons()),
      expect: () => [const LessonLoading(), const LessonEmpty()],
    );
  });
}
