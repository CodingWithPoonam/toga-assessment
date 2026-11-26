import '../models/quiz_question_model.dart';
import '../../domain/entities/quiz_question.dart';

/// PROVISIONAL_DEVELOPMENT_FIXTURE_NOT_OFFICIAL_AIRMAN_DATA
/// Isolated synthetic fixture supplying exactly five multiple-choice questions
class QuizFixtureDataSource {
  static const List<QuizQuestionModel> provisionalQuestions = [
    QuizQuestionModel(
      id: 'q1',
      lessonId: 'provisional_lesson_1',
      revisionId: 'rev_1_0',
      text:
          'What primary aerodynamic force overcomes an aircraft\'s weight during steady flight?',
      options: [
        QuizOption(id: 'opt_1a', text: 'Thrust'),
        QuizOption(id: 'opt_1b', text: 'Drag'),
        QuizOption(id: 'opt_1c', text: 'Lift'),
        QuizOption(id: 'opt_1d', text: 'Centrifugal Force'),
      ],
    ),
    QuizQuestionModel(
      id: 'q2',
      lessonId: 'provisional_lesson_1',
      revisionId: 'rev_1_0',
      text:
          'According to Bernoulli\'s principle, what happens to fluid pressure as velocity increases over a curved surface?',
      options: [
        QuizOption(id: 'opt_2a', text: 'Pressure increases proportionally'),
        QuizOption(id: 'opt_2b', text: 'Pressure decreases'),
        QuizOption(id: 'opt_2c', text: 'Pressure remains constant'),
        QuizOption(id: 'opt_2d', text: 'Pressure drops to zero immediately'),
      ],
    ),
    QuizQuestionModel(
      id: 'q3',
      lessonId: 'provisional_lesson_1',
      revisionId: 'rev_1_0',
      text:
          'Which flight instrument relies directly on dynamic ram air pressure from the pitot tube?',
      options: [
        QuizOption(id: 'opt_3a', text: 'Altimeter'),
        QuizOption(id: 'opt_3b', text: 'Vertical Speed Indicator (VSI)'),
        QuizOption(id: 'opt_3c', text: 'Airspeed Indicator (ASI)'),
        QuizOption(id: 'opt_3d', text: 'Magnetic Compass'),
      ],
    ),
    QuizQuestionModel(
      id: 'q4',
      lessonId: 'provisional_lesson_1',
      revisionId: 'rev_1_0',
      text:
          'Which primary flight control surface controls rotation about an aircraft\'s lateral axis (pitch)?',
      options: [
        QuizOption(id: 'opt_4a', text: 'Ailerons'),
        QuizOption(id: 'opt_4b', text: 'Elevators'),
        QuizOption(id: 'opt_4c', text: 'Rudder'),
        QuizOption(id: 'opt_4d', text: 'Trim tabs'),
      ],
    ),
    QuizQuestionModel(
      id: 'q5',
      lessonId: 'provisional_lesson_1',
      revisionId: 'rev_1_0',
      text:
          'What is the critical angle of attack beyond which an aerodynamic stall occurs?',
      options: [
        QuizOption(
          id: 'opt_5a',
          text: 'The angle where airflow separates from the upper wing surface',
        ),
        QuizOption(
          id: 'opt_5b',
          text: 'The angle where thrust equals total drag',
        ),
        QuizOption(id: 'opt_5c', text: 'The angle parallel to the horizon'),
        QuizOption(id: 'opt_5d', text: 'The maximum descent glide slope'),
      ],
    ),
  ];

  Future<List<QuizQuestionModel>> getQuestionsForLesson(String lessonId) async {
    return provisionalQuestions.where((q) => q.lessonId == lessonId).toList();
  }
}
