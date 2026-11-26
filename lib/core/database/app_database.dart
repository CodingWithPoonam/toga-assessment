import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/cached_lessons_table.dart';
import 'tables/quiz_answers_table.dart';
import 'tables/quiz_drafts_table.dart';

part 'app_database.g.dart';

/// Foundation metadata table for schema state and database integrity verification
class DatabaseMetadataTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Central database boundary for local persistence
/// Supports schema migrations, atomic writes, and background SQLite executor
@DriftDatabase(
  tables: [DatabaseMetadataTable, CachedLessons, QuizDrafts, QuizAnswers],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // Explicitly enforce SQLite foreign key constraints
      await customStatement('PRAGMA foreign_keys = ON;');
    },
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(cachedLessons);
        await m.createTable(quizDrafts);
        await m.createTable(quizAnswers);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'toga_app.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
