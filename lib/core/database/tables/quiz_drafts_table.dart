import 'package:drift/drift.dart';

/// Table tracking learner-isolated active quiz drafts and pinned revisions
class QuizDrafts extends Table {
  TextColumn get id => text()();
  TextColumn get learnerId => text()();
  TextColumn get lessonId => text()();
  TextColumn get revisionId => text()();
  IntColumn get currentQuestionIndex =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isSubmitted => boolean().withDefault(const Constant(false))();
  TextColumn get draftStatus =>
      text().withDefault(const Constant('in_progress'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {learnerId, lessonId},
  ];
}
