import '../models/lesson_model.dart';

/// Authoritative fixture datasource aligning with data/lessons.json in AIRMAN candidate kit
class LessonFixtureDataSource {
  final Duration simulatedDelay;

  // Active current revision per lesson ID (Scenario 07 allows bumping units to 2)
  final Map<String, int> _currentRevisions = {
    'lesson-units': 1,
    'lesson-practice': 1,
    'provisional_lesson_1': 1,
    'provisional_lesson_2': 1,
  };

  LessonFixtureDataSource({
    this.simulatedDelay = const Duration(milliseconds: 50),
  });

  /// Allows tests (e.g., Scenario 07) to advance the server's current revision
  void setServerRevision(String lessonId, int revision) {
    _currentRevisions[lessonId] = revision;
    if (lessonId == 'lesson-units') {
      _currentRevisions['provisional_lesson_1'] = revision;
    }
  }

  int getCurrentRevision(String lessonId) {
    return _currentRevisions[lessonId] ?? 1;
  }

  static const List<LessonModel> allLessons = [
    // 1. lesson-units revision 1 (Official)
    LessonModel(
      id: 'lesson-units',
      revisionId: '1',
      title: 'Aviation study units',
      summary:
          'Learn the listed units, then complete five questions. Synthetic TOGA hiring exercise content.',
      content:
          'Synthetic TOGA hiring exercise content. Learn the listed units, then complete five questions. This is not operational flight guidance.',
    ),
    // 2. lesson-units revision 2 (Official Scenario 07)
    LessonModel(
      id: 'lesson-units',
      revisionId: '2',
      title: 'Aviation study units revised',
      summary:
          'Learn the listed units, then complete five questions. Revised revision 2.',
      content:
          'Synthetic TOGA hiring exercise content. Learn the listed units, then complete five questions. This is not operational flight guidance.',
    ),
    // 3. lesson-practice revision 1 (Official)
    LessonModel(
      id: 'lesson-practice',
      revisionId: '1',
      title: 'Aviation practice questions',
      summary:
          'Practice five basic aviation questions. Synthetic TOGA hiring exercise content.',
      content:
          'Practice five basic aviation questions. Synthetic TOGA hiring exercise content. This is not operational flight guidance.',
    ),
    // Backward compatibility aliases for provisional lesson tests
    LessonModel(
      id: 'provisional_lesson_1',
      revisionId: 'rev_1_0',
      title: 'Aviation study units (Provisional)',
      summary: 'Fundamental lift, drag, thrust, and gravity concepts.',
      content: 'Synthetic TOGA hiring exercise content. Learn the listed units.',
    ),
    LessonModel(
      id: 'provisional_lesson_2',
      revisionId: 'rev_1_0',
      title: 'Aviation practice questions (Provisional)',
      summary: 'Altimeters, gyroscopes, and navigation systems.',
      content: 'Synthetic TOGA hiring exercise content.',
    ),
  ];

  Future<List<LessonModel>> fetchLessons() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    // Return the active revisions for the standard catalogue (lesson-units & lesson-practice)
    final unitsRev = (_currentRevisions['lesson-units'] ?? 1).toString();
    final practiceRev = (_currentRevisions['lesson-practice'] ?? 1).toString();

    final activeUnits = allLessons.firstWhere(
      (l) => l.id == 'lesson-units' && l.revisionId == unitsRev,
      orElse: () => allLessons.first,
    );
    final activePractice = allLessons.firstWhere(
      (l) => l.id == 'lesson-practice' && l.revisionId == practiceRev,
      orElse: () => allLessons[2],
    );

    return [activeUnits, activePractice];
  }

  Future<LessonModel?> fetchLessonById(String id, {String? revisionId}) async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    final targetRev = revisionId ?? (_currentRevisions[id] ?? 1).toString();
    try {
      // 1. Exact match first
      for (final l in allLessons) {
        if (l.id == id && (revisionId == null || l.revisionId == revisionId)) {
          return l;
        }
      }

      // 2. Mapped fallback
      return allLessons.firstWhere(
        (l) =>
            ((id == 'provisional_lesson_1' && l.id == 'lesson-units') ||
                (id == 'provisional_lesson_2' && l.id == 'lesson-practice')) &&
            (revisionId == null || l.revisionId == targetRev),
      );
    } catch (_) {
      return null;
    }
  }
}
