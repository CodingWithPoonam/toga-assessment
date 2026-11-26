import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toga_assessment/features/quiz/data/datasources/quiz_fixture_datasource.dart';
import 'package:toga_assessment/features/quiz/domain/entities/quiz_question.dart';
import 'package:toga_assessment/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:toga_assessment/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:toga_assessment/features/quiz/presentation/bloc/quiz_event.dart';
import 'package:toga_assessment/features/quiz/presentation/bloc/quiz_state.dart';

class MockQuizRepository extends Mock implements QuizRepository {}

void main() {
  late MockQuizRepository mockQuizRepository;
  late QuizBloc quizBloc;

  final List<QuizQuestion> sampleQuestions =
      QuizFixtureDataSource.provisionalQuestions;

  final sampleDraft = QuizDraft(
    id: 'learner-a_provisional_lesson_1',
    learnerId: 'learner-a',
    lessonId: 'provisional_lesson_1',
    revisionId: 'rev_1_0',
    currentQuestionIndex: 1,
    answers: const {'q1': 'opt_1c'},
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockQuizRepository = MockQuizRepository();
    quizBloc = QuizBloc(quizRepository: mockQuizRepository);
  });

  tearDown(() {
    quizBloc.close();
  });

  group('QuizBloc', () {
    test('initial state is QuizInitial', () {
      expect(quizBloc.state, equals(const QuizInitial()));
    });

    blocTest<QuizBloc, QuizState>(
      'StartQuiz starts fresh when no draft exists',
      build: () {
        when(
          () =>
              mockQuizRepository.getQuestionsForLesson('provisional_lesson_1'),
        ).thenAnswer((_) async => sampleQuestions);
        when(
          () => mockQuizRepository.getDraft('provisional_lesson_1'),
        ).thenAnswer((_) async => null);
        return quizBloc;
      },
      act: (bloc) => bloc.add(
        const StartQuiz(
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
        ),
      ),
      expect: () => [
        const QuizLoading(),
        QuizInProgress(
          questions: sampleQuestions,
          currentIndex: 0,
          answers: const {},
          revisionId: 'rev_1_0',
          isSavedOffline: false,
        ),
      ],
    );

    blocTest<QuizBloc, QuizState>(
      'StartQuiz restores existing draft when revision matches',
      build: () {
        when(
          () =>
              mockQuizRepository.getQuestionsForLesson('provisional_lesson_1'),
        ).thenAnswer((_) async => sampleQuestions);
        when(
          () => mockQuizRepository.getDraft('provisional_lesson_1'),
        ).thenAnswer((_) async => sampleDraft);
        return quizBloc;
      },
      act: (bloc) => bloc.add(
        const StartQuiz(
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
        ),
      ),
      expect: () => [
        const QuizLoading(),
        QuizInProgress(
          questions: sampleQuestions,
          currentIndex: 1,
          answers: const {'q1': 'opt_1c'},
          revisionId: 'rev_1_0',
          isSavedOffline: true,
        ),
      ],
    );

    blocTest<QuizBloc, QuizState>(
      'StartQuiz emits QuizRevisionMismatch when draft revision differs',
      build: () {
        when(
          () =>
              mockQuizRepository.getQuestionsForLesson('provisional_lesson_1'),
        ).thenAnswer((_) async => sampleQuestions);
        when(
          () => mockQuizRepository.getDraft('provisional_lesson_1'),
        ).thenAnswer(
          (_) async => sampleDraft.copyWith(revisionId: 'rev_0_9_old'),
        );
        return quizBloc;
      },
      act: (bloc) => bloc.add(
        const StartQuiz(
          lessonId: 'provisional_lesson_1',
          revisionId: 'rev_1_0',
        ),
      ),
      expect: () => [const QuizLoading(), isA<QuizRevisionMismatch>()],
    );

    blocTest<QuizBloc, QuizState>(
      'AnswerSelected updates answer map and calls repository.saveAnswer',
      build: () {
        when(
          () => mockQuizRepository.saveAnswer(
            lessonId: any(named: 'lessonId'),
            revisionId: any(named: 'revisionId'),
            questionId: any(named: 'questionId'),
            optionId: any(named: 'optionId'),
            currentQuestionIndex: any(named: 'currentQuestionIndex'),
          ),
        ).thenAnswer((_) async {});
        return quizBloc;
      },
      seed: () => QuizInProgress(
        questions: sampleQuestions,
        currentIndex: 0,
        answers: const {},
        revisionId: 'rev_1_0',
      ),
      act: (bloc) {
        bloc.add(const AnswerSelected(questionId: 'q1', optionId: 'opt_1c'));
      },
      expect: () => [],
    );
  });
}
