import 'package:drift/drift.dart';

/// Table storing durably cached lesson materials for offline reading
class CachedLessons extends Table {
  TextColumn get id => text()();
  TextColumn get revisionId => text()();
  TextColumn get title => text()();
  TextColumn get summary => text()();
  TextColumn get content => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
