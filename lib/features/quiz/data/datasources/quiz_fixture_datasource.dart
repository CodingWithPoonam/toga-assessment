import '../models/quiz_question_model.dart';
import '../../domain/entities/quiz_question.dart';

/// Authoritative synthetic fixture supplying questions matching data/lessons.json
class QuizFixtureDataSource {
  // Correct option indices per assessment README: [1, 0, 1, 0, 0]
  static const List<int> correctOptionIndices = [1, 0, 1, 0, 0];

  static List<QuizQuestionModel> get provisionalQuestions =>
      officialQuestions.where((q) => q.lessonId == 'provisional_lesson_1').toList();

  static const List<QuizQuestionModel> officialQuestions = [
    // ------------------------------------------------------------------------
    // lesson-units Revision 1 (Official)
    // ------------------------------------------------------------------------
    QuizQuestionModel(
      id: 'r1-u1',
      lessonId: 'lesson-units',
      revisionId: '1',
      text: 'How many minutes are in one hour?',
      options: [
        QuizOption(id: '0', text: '30'),
        QuizOption(id: '1', text: '60'),
        QuizOption(id: '2', text: '100'),
      ],
    ),
    QuizQuestionModel(
      id: 'r1-u2',
      lessonId: 'lesson-units',
      revisionId: '1',
      text: 'Which quantity is measured in metres?',
      options: [
        QuizOption(id: '0', text: 'Length'),
        QuizOption(id: '1', text: 'Time'),
        QuizOption(id: '2', text: 'Mass'),
      ],
    ),
    QuizQuestionModel(
      id: 'r1-u3',
      lessonId: 'lesson-units',
      revisionId: '1',
      text: 'Which quantity is measured in litres?',
      options: [
        QuizOption(id: '0', text: 'Speed'),
        QuizOption(id: '1', text: 'Volume'),
        QuizOption(id: '2', text: 'Distance'),
      ],
    ),
    QuizQuestionModel(
      id: 'r1-u4',
      lessonId: 'lesson-units',
      revisionId: '1',
      text: 'Which quantity is measured in knots?',
      options: [
        QuizOption(id: '0', text: 'Speed'),
        QuizOption(id: '1', text: 'Mass'),
        QuizOption(id: '2', text: 'Time'),
      ],
    ),
    QuizQuestionModel(
      id: 'r1-u5',
      lessonId: 'lesson-units',
      revisionId: '1',
      text: 'What does UTC stand for?',
      options: [
        QuizOption(id: '0', text: 'Coordinated Universal Time'),
        QuizOption(id: '1', text: 'Universal Training Count'),
        QuizOption(id: '2', text: 'Unit Time Clock'),
      ],
    ),

    // ------------------------------------------------------------------------
    // lesson-units Revision 2 (Official - Scenario 07)
    // ------------------------------------------------------------------------
    QuizQuestionModel(
      id: 'r2-u1',
      lessonId: 'lesson-units',
      revisionId: '2',
      text: 'How many minutes are in one hour?',
      options: [
        QuizOption(id: '0', text: '30'),
        QuizOption(id: '1', text: '60'),
        QuizOption(id: '2', text: '100'),
      ],
    ),
    QuizQuestionModel(
      id: 'r2-u2',
      lessonId: 'lesson-units',
      revisionId: '2',
      text: 'Which quantity is measured in metres?',
      options: [
        QuizOption(id: '0', text: 'Length'),
        QuizOption(id: '1', text: 'Time'),
        QuizOption(id: '2', text: 'Mass'),
      ],
    ),
    QuizQuestionModel(
      id: 'r2-u3',
      lessonId: 'lesson-units',
      revisionId: '2',
      text: 'Which quantity is measured in litres?',
      options: [
        QuizOption(id: '0', text: 'Speed'),
        QuizOption(id: '1', text: 'Volume'),
        QuizOption(id: '2', text: 'Distance'),
      ],
    ),
    QuizQuestionModel(
      id: 'r2-u4',
      lessonId: 'lesson-units',
      revisionId: '2',
      text: 'Which quantity is measured in knots?',
      options: [
        QuizOption(id: '0', text: 'Speed'),
        QuizOption(id: '1', text: 'Mass'),
        QuizOption(id: '2', text: 'Time'),
      ],
    ),
    QuizQuestionModel(
      id: 'r2-u5',
      lessonId: 'lesson-units',
      revisionId: '2',
      text: 'What does UTC stand for?',
      options: [
        QuizOption(id: '0', text: 'Coordinated Universal Time'),
        QuizOption(id: '1', text: 'Universal Training Count'),
        QuizOption(id: '2', text: 'Unit Time Clock'),
      ],
    ),

    // ------------------------------------------------------------------------
    // lesson-practice Revision 1 (Official)
    // ------------------------------------------------------------------------
    QuizQuestionModel(
      id: 'p1-u1',
      lessonId: 'lesson-practice',
      revisionId: '1',
      text: 'How many minutes are in one hour?',
      options: [
        QuizOption(id: '0', text: '30'),
        QuizOption(id: '1', text: '60'),
        QuizOption(id: '2', text: '100'),
      ],
    ),
    QuizQuestionModel(
      id: 'p1-u2',
      lessonId: 'lesson-practice',
      revisionId: '1',
      text: 'Which quantity is measured in metres?',
      options: [
        QuizOption(id: '0', text: 'Length'),
        QuizOption(id: '1', text: 'Time'),
        QuizOption(id: '2', text: 'Mass'),
      ],
    ),
    QuizQuestionModel(
      id: 'p1-u3',
      lessonId: 'lesson-practice',
      revisionId: '1',
      text: 'Which quantity is measured in litres?',
      options: [
        QuizOption(id: '0', text: 'Speed'),
        QuizOption(id: '1', text: 'Volume'),
        QuizOption(id: '2', text: 'Distance'),
      ],
    ),
    QuizQuestionModel(
      id: 'p1-u4',
      lessonId: 'lesson-practice',
      revisionId: '1',
      text: 'Which quantity is measured in knots?',
      options: [
        QuizOption(id: '0', text: 'Speed'),
        QuizOption(id: '1', text: 'Mass'),
        QuizOption(id: '2', text: 'Time'),
      ],
    ),
    QuizQuestionModel(
      id: 'p1-u5',
      lessonId: 'lesson-practice',
      revisionId: '1',
      text: 'What does UTC stand for?',
      options: [
        QuizOption(id: '0', text: 'Coordinated Universal Time'),
        QuizOption(id: '1', text: 'Universal Training Count'),
        QuizOption(id: '2', text: 'Unit Time Clock'),
      ],
    ),

    // ------------------------------------------------------------------------
    // Backward-compatible provisional aliases
    // ------------------------------------------------------------------------
    QuizQuestionModel(
      id: 'q1',
      lessonId: 'provisional_lesson_1',
      revisionId: 'rev_1_0',
      text: 'What primary aerodynamic force overcomes an aircraft\'s weight?',
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
      text: 'Fluid pressure as velocity increases over a curved surface?',
      options: [
        QuizOption(id: 'opt_2a', text: 'Pressure increases'),
        QuizOption(id: 'opt_2b', text: 'Pressure decreases'),
        QuizOption(id: 'opt_2c', text: 'Pressure remains constant'),
        QuizOption(id: 'opt_2d', text: 'Pressure drops to zero'),
      ],
    ),
    QuizQuestionModel(
      id: 'q3',
      lessonId: 'provisional_lesson_1',
      revisionId: 'rev_1_0',
      text: 'Which flight instrument relies on pitot tube dynamic pressure?',
      options: [
        QuizOption(id: 'opt_3a', text: 'Altimeter'),
        QuizOption(id: 'opt_3b', text: 'Vertical Speed Indicator'),
        QuizOption(id: 'opt_3c', text: 'Airspeed Indicator'),
        QuizOption(id: 'opt_3d', text: 'Magnetic Compass'),
      ],
    ),
    QuizQuestionModel(
      id: 'q4',
      lessonId: 'provisional_lesson_1',
      revisionId: 'rev_1_0',
      text: 'Which primary flight control surface controls pitch?',
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
      text: 'What is the critical angle of attack beyond which a stall occurs?',
      options: [
        QuizOption(id: 'opt_5a', text: 'Airflow separates from upper wing'),
        QuizOption(id: 'opt_5b', text: 'Thrust equals drag'),
        QuizOption(id: 'opt_5c', text: 'Angle parallel to horizon'),
        QuizOption(id: 'opt_5d', text: 'Maximum descent glide slope'),
      ],
    ),
  ];

  Future<List<QuizQuestionModel>> getQuestionsForLesson(
    String lessonId, {
    String? revisionId,
  }) async {
    // 1. Check exact match for lessonId (including provisional aliases)
    final exact = officialQuestions.where((q) {
      final matchesLesson = q.lessonId == lessonId;
      final matchesRev = revisionId == null ||
          q.revisionId == revisionId ||
          (revisionId == 'rev_1_0' && q.revisionId == '1') ||
          (revisionId == '1' && q.revisionId == 'rev_1_0');
      return matchesLesson && matchesRev;
    }).toList();

    if (exact.isNotEmpty) {
      return exact.take(5).toList();
    }

    // 2. Normalized fallback
    final normalizedLessonId = lessonId == 'provisional_lesson_1'
        ? 'lesson-units'
        : (lessonId == 'provisional_lesson_2' ? 'lesson-practice' : lessonId);

    final questions = officialQuestions.where((q) {
      final matchesLesson = q.lessonId == lessonId || q.lessonId == normalizedLessonId;
      final matchesRev = revisionId == null ||
          q.revisionId == revisionId ||
          (revisionId == 'rev_1_0' && q.revisionId == '1') ||
          (revisionId == '1' && q.revisionId == 'rev_1_0');
      return matchesLesson && matchesRev;
    }).toList();

    if (questions.isNotEmpty) {
      return questions.take(5).toList();
    }

    return officialQuestions.where((q) => q.lessonId == lessonId).take(5).toList();
  }
}
