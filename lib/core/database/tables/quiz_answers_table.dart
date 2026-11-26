import 'package:drift/drift.dart';
import 'quiz_drafts_table.dart';

/// Table persisting individual question answers with encrypted payload protection
class QuizAnswers extends Table {
  TextColumn get id => text()();
  TextColumn get draftId =>
      text().references(QuizDrafts, #id, onDelete: KeyAction.cascade)();
  TextColumn get learnerId => text()();
  TextColumn get questionId => text()();
  TextColumn get encryptedSelectedOptionId => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {draftId, questionId},
  ];
}
