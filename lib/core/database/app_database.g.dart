// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DatabaseMetadataTableTable extends DatabaseMetadataTable
    with TableInfo<$DatabaseMetadataTableTable, DatabaseMetadataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatabaseMetadataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'database_metadata_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<DatabaseMetadataTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  DatabaseMetadataTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatabaseMetadataTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $DatabaseMetadataTableTable createAlias(String alias) {
    return $DatabaseMetadataTableTable(attachedDatabase, alias);
  }
}

class DatabaseMetadataTableData extends DataClass
    implements Insertable<DatabaseMetadataTableData> {
  final String key;
  final String value;
  const DatabaseMetadataTableData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  DatabaseMetadataTableCompanion toCompanion(bool nullToAbsent) {
    return DatabaseMetadataTableCompanion(key: Value(key), value: Value(value));
  }

  factory DatabaseMetadataTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatabaseMetadataTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  DatabaseMetadataTableData copyWith({String? key, String? value}) =>
      DatabaseMetadataTableData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  DatabaseMetadataTableData copyWithCompanion(
    DatabaseMetadataTableCompanion data,
  ) {
    return DatabaseMetadataTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatabaseMetadataTableData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatabaseMetadataTableData &&
          other.key == this.key &&
          other.value == this.value);
}

class DatabaseMetadataTableCompanion
    extends UpdateCompanion<DatabaseMetadataTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const DatabaseMetadataTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DatabaseMetadataTableCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<DatabaseMetadataTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DatabaseMetadataTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return DatabaseMetadataTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatabaseMetadataTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedLessonsTable extends CachedLessons
    with TableInfo<$CachedLessonsTable, CachedLesson> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedLessonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionIdMeta = const VerificationMeta(
    'revisionId',
  );
  @override
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
    'revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    revisionId,
    title,
    summary,
    content,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_lessons';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedLesson> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('revision_id')) {
      context.handle(
        _revisionIdMeta,
        revisionId.isAcceptableOrUnknown(data['revision_id']!, _revisionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedLesson map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedLesson(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      revisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedLessonsTable createAlias(String alias) {
    return $CachedLessonsTable(attachedDatabase, alias);
  }
}

class CachedLesson extends DataClass implements Insertable<CachedLesson> {
  final String id;
  final String revisionId;
  final String title;
  final String summary;
  final String content;
  final DateTime cachedAt;
  const CachedLesson({
    required this.id,
    required this.revisionId,
    required this.title,
    required this.summary,
    required this.content,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['revision_id'] = Variable<String>(revisionId);
    map['title'] = Variable<String>(title);
    map['summary'] = Variable<String>(summary);
    map['content'] = Variable<String>(content);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedLessonsCompanion toCompanion(bool nullToAbsent) {
    return CachedLessonsCompanion(
      id: Value(id),
      revisionId: Value(revisionId),
      title: Value(title),
      summary: Value(summary),
      content: Value(content),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedLesson.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedLesson(
      id: serializer.fromJson<String>(json['id']),
      revisionId: serializer.fromJson<String>(json['revisionId']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String>(json['summary']),
      content: serializer.fromJson<String>(json['content']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'revisionId': serializer.toJson<String>(revisionId),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String>(summary),
      'content': serializer.toJson<String>(content),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedLesson copyWith({
    String? id,
    String? revisionId,
    String? title,
    String? summary,
    String? content,
    DateTime? cachedAt,
  }) => CachedLesson(
    id: id ?? this.id,
    revisionId: revisionId ?? this.revisionId,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    content: content ?? this.content,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedLesson copyWithCompanion(CachedLessonsCompanion data) {
    return CachedLesson(
      id: data.id.present ? data.id.value : this.id,
      revisionId: data.revisionId.present
          ? data.revisionId.value
          : this.revisionId,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      content: data.content.present ? data.content.value : this.content,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedLesson(')
          ..write('id: $id, ')
          ..write('revisionId: $revisionId, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('content: $content, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, revisionId, title, summary, content, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedLesson &&
          other.id == this.id &&
          other.revisionId == this.revisionId &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.content == this.content &&
          other.cachedAt == this.cachedAt);
}

class CachedLessonsCompanion extends UpdateCompanion<CachedLesson> {
  final Value<String> id;
  final Value<String> revisionId;
  final Value<String> title;
  final Value<String> summary;
  final Value<String> content;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedLessonsCompanion({
    this.id = const Value.absent(),
    this.revisionId = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.content = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedLessonsCompanion.insert({
    required String id,
    required String revisionId,
    required String title,
    required String summary,
    required String content,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       revisionId = Value(revisionId),
       title = Value(title),
       summary = Value(summary),
       content = Value(content),
       cachedAt = Value(cachedAt);
  static Insertable<CachedLesson> custom({
    Expression<String>? id,
    Expression<String>? revisionId,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? content,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (revisionId != null) 'revision_id': revisionId,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (content != null) 'content': content,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedLessonsCompanion copyWith({
    Value<String>? id,
    Value<String>? revisionId,
    Value<String>? title,
    Value<String>? summary,
    Value<String>? content,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedLessonsCompanion(
      id: id ?? this.id,
      revisionId: revisionId ?? this.revisionId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedLessonsCompanion(')
          ..write('id: $id, ')
          ..write('revisionId: $revisionId, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('content: $content, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuizDraftsTable extends QuizDrafts
    with TableInfo<$QuizDraftsTable, QuizDraft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizDraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learnerIdMeta = const VerificationMeta(
    'learnerId',
  );
  @override
  late final GeneratedColumn<String> learnerId = GeneratedColumn<String>(
    'learner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionIdMeta = const VerificationMeta(
    'revisionId',
  );
  @override
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
    'revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentQuestionIndexMeta =
      const VerificationMeta('currentQuestionIndex');
  @override
  late final GeneratedColumn<int> currentQuestionIndex = GeneratedColumn<int>(
    'current_question_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSubmittedMeta = const VerificationMeta(
    'isSubmitted',
  );
  @override
  late final GeneratedColumn<bool> isSubmitted = GeneratedColumn<bool>(
    'is_submitted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_submitted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    learnerId,
    lessonId,
    revisionId,
    currentQuestionIndex,
    isSubmitted,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizDraft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('learner_id')) {
      context.handle(
        _learnerIdMeta,
        learnerId.isAcceptableOrUnknown(data['learner_id']!, _learnerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_learnerIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('revision_id')) {
      context.handle(
        _revisionIdMeta,
        revisionId.isAcceptableOrUnknown(data['revision_id']!, _revisionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionIdMeta);
    }
    if (data.containsKey('current_question_index')) {
      context.handle(
        _currentQuestionIndexMeta,
        currentQuestionIndex.isAcceptableOrUnknown(
          data['current_question_index']!,
          _currentQuestionIndexMeta,
        ),
      );
    }
    if (data.containsKey('is_submitted')) {
      context.handle(
        _isSubmittedMeta,
        isSubmitted.isAcceptableOrUnknown(
          data['is_submitted']!,
          _isSubmittedMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {learnerId, lessonId},
  ];
  @override
  QuizDraft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizDraft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      learnerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learner_id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      revisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_id'],
      )!,
      currentQuestionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_question_index'],
      )!,
      isSubmitted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_submitted'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QuizDraftsTable createAlias(String alias) {
    return $QuizDraftsTable(attachedDatabase, alias);
  }
}

class QuizDraft extends DataClass implements Insertable<QuizDraft> {
  final String id;
  final String learnerId;
  final String lessonId;
  final String revisionId;
  final int currentQuestionIndex;
  final bool isSubmitted;
  final DateTime updatedAt;
  const QuizDraft({
    required this.id,
    required this.learnerId,
    required this.lessonId,
    required this.revisionId,
    required this.currentQuestionIndex,
    required this.isSubmitted,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['learner_id'] = Variable<String>(learnerId);
    map['lesson_id'] = Variable<String>(lessonId);
    map['revision_id'] = Variable<String>(revisionId);
    map['current_question_index'] = Variable<int>(currentQuestionIndex);
    map['is_submitted'] = Variable<bool>(isSubmitted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QuizDraftsCompanion toCompanion(bool nullToAbsent) {
    return QuizDraftsCompanion(
      id: Value(id),
      learnerId: Value(learnerId),
      lessonId: Value(lessonId),
      revisionId: Value(revisionId),
      currentQuestionIndex: Value(currentQuestionIndex),
      isSubmitted: Value(isSubmitted),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuizDraft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizDraft(
      id: serializer.fromJson<String>(json['id']),
      learnerId: serializer.fromJson<String>(json['learnerId']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      revisionId: serializer.fromJson<String>(json['revisionId']),
      currentQuestionIndex: serializer.fromJson<int>(
        json['currentQuestionIndex'],
      ),
      isSubmitted: serializer.fromJson<bool>(json['isSubmitted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'learnerId': serializer.toJson<String>(learnerId),
      'lessonId': serializer.toJson<String>(lessonId),
      'revisionId': serializer.toJson<String>(revisionId),
      'currentQuestionIndex': serializer.toJson<int>(currentQuestionIndex),
      'isSubmitted': serializer.toJson<bool>(isSubmitted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QuizDraft copyWith({
    String? id,
    String? learnerId,
    String? lessonId,
    String? revisionId,
    int? currentQuestionIndex,
    bool? isSubmitted,
    DateTime? updatedAt,
  }) => QuizDraft(
    id: id ?? this.id,
    learnerId: learnerId ?? this.learnerId,
    lessonId: lessonId ?? this.lessonId,
    revisionId: revisionId ?? this.revisionId,
    currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    isSubmitted: isSubmitted ?? this.isSubmitted,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QuizDraft copyWithCompanion(QuizDraftsCompanion data) {
    return QuizDraft(
      id: data.id.present ? data.id.value : this.id,
      learnerId: data.learnerId.present ? data.learnerId.value : this.learnerId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      revisionId: data.revisionId.present
          ? data.revisionId.value
          : this.revisionId,
      currentQuestionIndex: data.currentQuestionIndex.present
          ? data.currentQuestionIndex.value
          : this.currentQuestionIndex,
      isSubmitted: data.isSubmitted.present
          ? data.isSubmitted.value
          : this.isSubmitted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizDraft(')
          ..write('id: $id, ')
          ..write('learnerId: $learnerId, ')
          ..write('lessonId: $lessonId, ')
          ..write('revisionId: $revisionId, ')
          ..write('currentQuestionIndex: $currentQuestionIndex, ')
          ..write('isSubmitted: $isSubmitted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    learnerId,
    lessonId,
    revisionId,
    currentQuestionIndex,
    isSubmitted,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizDraft &&
          other.id == this.id &&
          other.learnerId == this.learnerId &&
          other.lessonId == this.lessonId &&
          other.revisionId == this.revisionId &&
          other.currentQuestionIndex == this.currentQuestionIndex &&
          other.isSubmitted == this.isSubmitted &&
          other.updatedAt == this.updatedAt);
}

class QuizDraftsCompanion extends UpdateCompanion<QuizDraft> {
  final Value<String> id;
  final Value<String> learnerId;
  final Value<String> lessonId;
  final Value<String> revisionId;
  final Value<int> currentQuestionIndex;
  final Value<bool> isSubmitted;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const QuizDraftsCompanion({
    this.id = const Value.absent(),
    this.learnerId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.revisionId = const Value.absent(),
    this.currentQuestionIndex = const Value.absent(),
    this.isSubmitted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizDraftsCompanion.insert({
    required String id,
    required String learnerId,
    required String lessonId,
    required String revisionId,
    this.currentQuestionIndex = const Value.absent(),
    this.isSubmitted = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       learnerId = Value(learnerId),
       lessonId = Value(lessonId),
       revisionId = Value(revisionId),
       updatedAt = Value(updatedAt);
  static Insertable<QuizDraft> custom({
    Expression<String>? id,
    Expression<String>? learnerId,
    Expression<String>? lessonId,
    Expression<String>? revisionId,
    Expression<int>? currentQuestionIndex,
    Expression<bool>? isSubmitted,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (learnerId != null) 'learner_id': learnerId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (revisionId != null) 'revision_id': revisionId,
      if (currentQuestionIndex != null)
        'current_question_index': currentQuestionIndex,
      if (isSubmitted != null) 'is_submitted': isSubmitted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizDraftsCompanion copyWith({
    Value<String>? id,
    Value<String>? learnerId,
    Value<String>? lessonId,
    Value<String>? revisionId,
    Value<int>? currentQuestionIndex,
    Value<bool>? isSubmitted,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return QuizDraftsCompanion(
      id: id ?? this.id,
      learnerId: learnerId ?? this.learnerId,
      lessonId: lessonId ?? this.lessonId,
      revisionId: revisionId ?? this.revisionId,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (learnerId.present) {
      map['learner_id'] = Variable<String>(learnerId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    if (currentQuestionIndex.present) {
      map['current_question_index'] = Variable<int>(currentQuestionIndex.value);
    }
    if (isSubmitted.present) {
      map['is_submitted'] = Variable<bool>(isSubmitted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizDraftsCompanion(')
          ..write('id: $id, ')
          ..write('learnerId: $learnerId, ')
          ..write('lessonId: $lessonId, ')
          ..write('revisionId: $revisionId, ')
          ..write('currentQuestionIndex: $currentQuestionIndex, ')
          ..write('isSubmitted: $isSubmitted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuizAnswersTable extends QuizAnswers
    with TableInfo<$QuizAnswersTable, QuizAnswer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _draftIdMeta = const VerificationMeta(
    'draftId',
  );
  @override
  late final GeneratedColumn<String> draftId = GeneratedColumn<String>(
    'draft_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES quiz_drafts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedSelectedOptionIdMeta =
      const VerificationMeta('encryptedSelectedOptionId');
  @override
  late final GeneratedColumn<String> encryptedSelectedOptionId =
      GeneratedColumn<String>(
        'encrypted_selected_option_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    draftId,
    questionId,
    encryptedSelectedOptionId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_answers';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizAnswer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('draft_id')) {
      context.handle(
        _draftIdMeta,
        draftId.isAcceptableOrUnknown(data['draft_id']!, _draftIdMeta),
      );
    } else if (isInserting) {
      context.missing(_draftIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('encrypted_selected_option_id')) {
      context.handle(
        _encryptedSelectedOptionIdMeta,
        encryptedSelectedOptionId.isAcceptableOrUnknown(
          data['encrypted_selected_option_id']!,
          _encryptedSelectedOptionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedSelectedOptionIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {draftId, questionId},
  ];
  @override
  QuizAnswer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizAnswer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      draftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      encryptedSelectedOptionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_selected_option_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QuizAnswersTable createAlias(String alias) {
    return $QuizAnswersTable(attachedDatabase, alias);
  }
}

class QuizAnswer extends DataClass implements Insertable<QuizAnswer> {
  final String id;
  final String draftId;
  final String questionId;
  final String encryptedSelectedOptionId;
  final DateTime updatedAt;
  const QuizAnswer({
    required this.id,
    required this.draftId,
    required this.questionId,
    required this.encryptedSelectedOptionId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['draft_id'] = Variable<String>(draftId);
    map['question_id'] = Variable<String>(questionId);
    map['encrypted_selected_option_id'] = Variable<String>(
      encryptedSelectedOptionId,
    );
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QuizAnswersCompanion toCompanion(bool nullToAbsent) {
    return QuizAnswersCompanion(
      id: Value(id),
      draftId: Value(draftId),
      questionId: Value(questionId),
      encryptedSelectedOptionId: Value(encryptedSelectedOptionId),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuizAnswer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizAnswer(
      id: serializer.fromJson<String>(json['id']),
      draftId: serializer.fromJson<String>(json['draftId']),
      questionId: serializer.fromJson<String>(json['questionId']),
      encryptedSelectedOptionId: serializer.fromJson<String>(
        json['encryptedSelectedOptionId'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'draftId': serializer.toJson<String>(draftId),
      'questionId': serializer.toJson<String>(questionId),
      'encryptedSelectedOptionId': serializer.toJson<String>(
        encryptedSelectedOptionId,
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QuizAnswer copyWith({
    String? id,
    String? draftId,
    String? questionId,
    String? encryptedSelectedOptionId,
    DateTime? updatedAt,
  }) => QuizAnswer(
    id: id ?? this.id,
    draftId: draftId ?? this.draftId,
    questionId: questionId ?? this.questionId,
    encryptedSelectedOptionId:
        encryptedSelectedOptionId ?? this.encryptedSelectedOptionId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QuizAnswer copyWithCompanion(QuizAnswersCompanion data) {
    return QuizAnswer(
      id: data.id.present ? data.id.value : this.id,
      draftId: data.draftId.present ? data.draftId.value : this.draftId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      encryptedSelectedOptionId: data.encryptedSelectedOptionId.present
          ? data.encryptedSelectedOptionId.value
          : this.encryptedSelectedOptionId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizAnswer(')
          ..write('id: $id, ')
          ..write('draftId: $draftId, ')
          ..write('questionId: $questionId, ')
          ..write('encryptedSelectedOptionId: $encryptedSelectedOptionId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    draftId,
    questionId,
    encryptedSelectedOptionId,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizAnswer &&
          other.id == this.id &&
          other.draftId == this.draftId &&
          other.questionId == this.questionId &&
          other.encryptedSelectedOptionId == this.encryptedSelectedOptionId &&
          other.updatedAt == this.updatedAt);
}

class QuizAnswersCompanion extends UpdateCompanion<QuizAnswer> {
  final Value<String> id;
  final Value<String> draftId;
  final Value<String> questionId;
  final Value<String> encryptedSelectedOptionId;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const QuizAnswersCompanion({
    this.id = const Value.absent(),
    this.draftId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.encryptedSelectedOptionId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizAnswersCompanion.insert({
    required String id,
    required String draftId,
    required String questionId,
    required String encryptedSelectedOptionId,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       draftId = Value(draftId),
       questionId = Value(questionId),
       encryptedSelectedOptionId = Value(encryptedSelectedOptionId),
       updatedAt = Value(updatedAt);
  static Insertable<QuizAnswer> custom({
    Expression<String>? id,
    Expression<String>? draftId,
    Expression<String>? questionId,
    Expression<String>? encryptedSelectedOptionId,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (draftId != null) 'draft_id': draftId,
      if (questionId != null) 'question_id': questionId,
      if (encryptedSelectedOptionId != null)
        'encrypted_selected_option_id': encryptedSelectedOptionId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizAnswersCompanion copyWith({
    Value<String>? id,
    Value<String>? draftId,
    Value<String>? questionId,
    Value<String>? encryptedSelectedOptionId,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return QuizAnswersCompanion(
      id: id ?? this.id,
      draftId: draftId ?? this.draftId,
      questionId: questionId ?? this.questionId,
      encryptedSelectedOptionId:
          encryptedSelectedOptionId ?? this.encryptedSelectedOptionId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (draftId.present) {
      map['draft_id'] = Variable<String>(draftId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (encryptedSelectedOptionId.present) {
      map['encrypted_selected_option_id'] = Variable<String>(
        encryptedSelectedOptionId.value,
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizAnswersCompanion(')
          ..write('id: $id, ')
          ..write('draftId: $draftId, ')
          ..write('questionId: $questionId, ')
          ..write('encryptedSelectedOptionId: $encryptedSelectedOptionId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DatabaseMetadataTableTable databaseMetadataTable =
      $DatabaseMetadataTableTable(this);
  late final $CachedLessonsTable cachedLessons = $CachedLessonsTable(this);
  late final $QuizDraftsTable quizDrafts = $QuizDraftsTable(this);
  late final $QuizAnswersTable quizAnswers = $QuizAnswersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    databaseMetadataTable,
    cachedLessons,
    quizDrafts,
    quizAnswers,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'quiz_drafts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('quiz_answers', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DatabaseMetadataTableTableCreateCompanionBuilder =
    DatabaseMetadataTableCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$DatabaseMetadataTableTableUpdateCompanionBuilder =
    DatabaseMetadataTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$DatabaseMetadataTableTableFilterComposer
    extends Composer<_$AppDatabase, $DatabaseMetadataTableTable> {
  $$DatabaseMetadataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DatabaseMetadataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DatabaseMetadataTableTable> {
  $$DatabaseMetadataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DatabaseMetadataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatabaseMetadataTableTable> {
  $$DatabaseMetadataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$DatabaseMetadataTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DatabaseMetadataTableTable,
          DatabaseMetadataTableData,
          $$DatabaseMetadataTableTableFilterComposer,
          $$DatabaseMetadataTableTableOrderingComposer,
          $$DatabaseMetadataTableTableAnnotationComposer,
          $$DatabaseMetadataTableTableCreateCompanionBuilder,
          $$DatabaseMetadataTableTableUpdateCompanionBuilder,
          (
            DatabaseMetadataTableData,
            BaseReferences<
              _$AppDatabase,
              $DatabaseMetadataTableTable,
              DatabaseMetadataTableData
            >,
          ),
          DatabaseMetadataTableData,
          PrefetchHooks Function()
        > {
  $$DatabaseMetadataTableTableTableManager(
    _$AppDatabase db,
    $DatabaseMetadataTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatabaseMetadataTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DatabaseMetadataTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DatabaseMetadataTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DatabaseMetadataTableCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => DatabaseMetadataTableCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DatabaseMetadataTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DatabaseMetadataTableTable,
      DatabaseMetadataTableData,
      $$DatabaseMetadataTableTableFilterComposer,
      $$DatabaseMetadataTableTableOrderingComposer,
      $$DatabaseMetadataTableTableAnnotationComposer,
      $$DatabaseMetadataTableTableCreateCompanionBuilder,
      $$DatabaseMetadataTableTableUpdateCompanionBuilder,
      (
        DatabaseMetadataTableData,
        BaseReferences<
          _$AppDatabase,
          $DatabaseMetadataTableTable,
          DatabaseMetadataTableData
        >,
      ),
      DatabaseMetadataTableData,
      PrefetchHooks Function()
    >;
typedef $$CachedLessonsTableCreateCompanionBuilder =
    CachedLessonsCompanion Function({
      required String id,
      required String revisionId,
      required String title,
      required String summary,
      required String content,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$CachedLessonsTableUpdateCompanionBuilder =
    CachedLessonsCompanion Function({
      Value<String> id,
      Value<String> revisionId,
      Value<String> title,
      Value<String> summary,
      Value<String> content,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedLessonsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedLessonsTable> {
  $$CachedLessonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedLessonsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedLessonsTable> {
  $$CachedLessonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedLessonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedLessonsTable> {
  $$CachedLessonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedLessonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedLessonsTable,
          CachedLesson,
          $$CachedLessonsTableFilterComposer,
          $$CachedLessonsTableOrderingComposer,
          $$CachedLessonsTableAnnotationComposer,
          $$CachedLessonsTableCreateCompanionBuilder,
          $$CachedLessonsTableUpdateCompanionBuilder,
          (
            CachedLesson,
            BaseReferences<_$AppDatabase, $CachedLessonsTable, CachedLesson>,
          ),
          CachedLesson,
          PrefetchHooks Function()
        > {
  $$CachedLessonsTableTableManager(_$AppDatabase db, $CachedLessonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedLessonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedLessonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedLessonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> revisionId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedLessonsCompanion(
                id: id,
                revisionId: revisionId,
                title: title,
                summary: summary,
                content: content,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String revisionId,
                required String title,
                required String summary,
                required String content,
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedLessonsCompanion.insert(
                id: id,
                revisionId: revisionId,
                title: title,
                summary: summary,
                content: content,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedLessonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedLessonsTable,
      CachedLesson,
      $$CachedLessonsTableFilterComposer,
      $$CachedLessonsTableOrderingComposer,
      $$CachedLessonsTableAnnotationComposer,
      $$CachedLessonsTableCreateCompanionBuilder,
      $$CachedLessonsTableUpdateCompanionBuilder,
      (
        CachedLesson,
        BaseReferences<_$AppDatabase, $CachedLessonsTable, CachedLesson>,
      ),
      CachedLesson,
      PrefetchHooks Function()
    >;
typedef $$QuizDraftsTableCreateCompanionBuilder =
    QuizDraftsCompanion Function({
      required String id,
      required String learnerId,
      required String lessonId,
      required String revisionId,
      Value<int> currentQuestionIndex,
      Value<bool> isSubmitted,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$QuizDraftsTableUpdateCompanionBuilder =
    QuizDraftsCompanion Function({
      Value<String> id,
      Value<String> learnerId,
      Value<String> lessonId,
      Value<String> revisionId,
      Value<int> currentQuestionIndex,
      Value<bool> isSubmitted,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$QuizDraftsTableReferences
    extends BaseReferences<_$AppDatabase, $QuizDraftsTable, QuizDraft> {
  $$QuizDraftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$QuizAnswersTable, List<QuizAnswer>>
  _quizAnswersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.quizAnswers,
    aliasName: 'quiz_drafts__id__quiz_answers__draft_id',
  );

  $$QuizAnswersTableProcessedTableManager get quizAnswersRefs {
    final manager = $$QuizAnswersTableTableManager(
      $_db,
      $_db.quizAnswers,
    ).filter((f) => f.draftId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_quizAnswersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$QuizDraftsTableFilterComposer
    extends Composer<_$AppDatabase, $QuizDraftsTable> {
  $$QuizDraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get learnerId => $composableBuilder(
    column: $table.learnerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentQuestionIndex => $composableBuilder(
    column: $table.currentQuestionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSubmitted => $composableBuilder(
    column: $table.isSubmitted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> quizAnswersRefs(
    Expression<bool> Function($$QuizAnswersTableFilterComposer f) f,
  ) {
    final $$QuizAnswersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quizAnswers,
      getReferencedColumn: (t) => t.draftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuizAnswersTableFilterComposer(
            $db: $db,
            $table: $db.quizAnswers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuizDraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizDraftsTable> {
  $$QuizDraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get learnerId => $composableBuilder(
    column: $table.learnerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentQuestionIndex => $composableBuilder(
    column: $table.currentQuestionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSubmitted => $composableBuilder(
    column: $table.isSubmitted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuizDraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizDraftsTable> {
  $$QuizDraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get learnerId =>
      $composableBuilder(column: $table.learnerId, builder: (column) => column);

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get revisionId => $composableBuilder(
    column: $table.revisionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentQuestionIndex => $composableBuilder(
    column: $table.currentQuestionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSubmitted => $composableBuilder(
    column: $table.isSubmitted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> quizAnswersRefs<T extends Object>(
    Expression<T> Function($$QuizAnswersTableAnnotationComposer a) f,
  ) {
    final $$QuizAnswersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.quizAnswers,
      getReferencedColumn: (t) => t.draftId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuizAnswersTableAnnotationComposer(
            $db: $db,
            $table: $db.quizAnswers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$QuizDraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizDraftsTable,
          QuizDraft,
          $$QuizDraftsTableFilterComposer,
          $$QuizDraftsTableOrderingComposer,
          $$QuizDraftsTableAnnotationComposer,
          $$QuizDraftsTableCreateCompanionBuilder,
          $$QuizDraftsTableUpdateCompanionBuilder,
          (QuizDraft, $$QuizDraftsTableReferences),
          QuizDraft,
          PrefetchHooks Function({bool quizAnswersRefs})
        > {
  $$QuizDraftsTableTableManager(_$AppDatabase db, $QuizDraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizDraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizDraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizDraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> learnerId = const Value.absent(),
                Value<String> lessonId = const Value.absent(),
                Value<String> revisionId = const Value.absent(),
                Value<int> currentQuestionIndex = const Value.absent(),
                Value<bool> isSubmitted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizDraftsCompanion(
                id: id,
                learnerId: learnerId,
                lessonId: lessonId,
                revisionId: revisionId,
                currentQuestionIndex: currentQuestionIndex,
                isSubmitted: isSubmitted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String learnerId,
                required String lessonId,
                required String revisionId,
                Value<int> currentQuestionIndex = const Value.absent(),
                Value<bool> isSubmitted = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuizDraftsCompanion.insert(
                id: id,
                learnerId: learnerId,
                lessonId: lessonId,
                revisionId: revisionId,
                currentQuestionIndex: currentQuestionIndex,
                isSubmitted: isSubmitted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuizDraftsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({quizAnswersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (quizAnswersRefs) db.quizAnswers],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (quizAnswersRefs)
                    await $_getPrefetchedData<
                      QuizDraft,
                      $QuizDraftsTable,
                      QuizAnswer
                    >(
                      currentTable: table,
                      referencedTable: $$QuizDraftsTableReferences
                          ._quizAnswersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$QuizDraftsTableReferences(
                            db,
                            table,
                            p0,
                          ).quizAnswersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.draftId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$QuizDraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizDraftsTable,
      QuizDraft,
      $$QuizDraftsTableFilterComposer,
      $$QuizDraftsTableOrderingComposer,
      $$QuizDraftsTableAnnotationComposer,
      $$QuizDraftsTableCreateCompanionBuilder,
      $$QuizDraftsTableUpdateCompanionBuilder,
      (QuizDraft, $$QuizDraftsTableReferences),
      QuizDraft,
      PrefetchHooks Function({bool quizAnswersRefs})
    >;
typedef $$QuizAnswersTableCreateCompanionBuilder =
    QuizAnswersCompanion Function({
      required String id,
      required String draftId,
      required String questionId,
      required String encryptedSelectedOptionId,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$QuizAnswersTableUpdateCompanionBuilder =
    QuizAnswersCompanion Function({
      Value<String> id,
      Value<String> draftId,
      Value<String> questionId,
      Value<String> encryptedSelectedOptionId,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$QuizAnswersTableReferences
    extends BaseReferences<_$AppDatabase, $QuizAnswersTable, QuizAnswer> {
  $$QuizAnswersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $QuizDraftsTable _draftIdTable(_$AppDatabase db) =>
      db.quizDrafts.createAlias('quiz_answers__draft_id__quiz_drafts__id');

  $$QuizDraftsTableProcessedTableManager get draftId {
    final $_column = $_itemColumn<String>('draft_id')!;

    final manager = $$QuizDraftsTableTableManager(
      $_db,
      $_db.quizDrafts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_draftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuizAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $QuizAnswersTable> {
  $$QuizAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedSelectedOptionId => $composableBuilder(
    column: $table.encryptedSelectedOptionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$QuizDraftsTableFilterComposer get draftId {
    final $$QuizDraftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.draftId,
      referencedTable: $db.quizDrafts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuizDraftsTableFilterComposer(
            $db: $db,
            $table: $db.quizDrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuizAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizAnswersTable> {
  $$QuizAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedSelectedOptionId => $composableBuilder(
    column: $table.encryptedSelectedOptionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$QuizDraftsTableOrderingComposer get draftId {
    final $$QuizDraftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.draftId,
      referencedTable: $db.quizDrafts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuizDraftsTableOrderingComposer(
            $db: $db,
            $table: $db.quizDrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuizAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizAnswersTable> {
  $$QuizAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get encryptedSelectedOptionId => $composableBuilder(
    column: $table.encryptedSelectedOptionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$QuizDraftsTableAnnotationComposer get draftId {
    final $$QuizDraftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.draftId,
      referencedTable: $db.quizDrafts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuizDraftsTableAnnotationComposer(
            $db: $db,
            $table: $db.quizDrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuizAnswersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizAnswersTable,
          QuizAnswer,
          $$QuizAnswersTableFilterComposer,
          $$QuizAnswersTableOrderingComposer,
          $$QuizAnswersTableAnnotationComposer,
          $$QuizAnswersTableCreateCompanionBuilder,
          $$QuizAnswersTableUpdateCompanionBuilder,
          (QuizAnswer, $$QuizAnswersTableReferences),
          QuizAnswer,
          PrefetchHooks Function({bool draftId})
        > {
  $$QuizAnswersTableTableManager(_$AppDatabase db, $QuizAnswersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizAnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> draftId = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String> encryptedSelectedOptionId = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizAnswersCompanion(
                id: id,
                draftId: draftId,
                questionId: questionId,
                encryptedSelectedOptionId: encryptedSelectedOptionId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String draftId,
                required String questionId,
                required String encryptedSelectedOptionId,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuizAnswersCompanion.insert(
                id: id,
                draftId: draftId,
                questionId: questionId,
                encryptedSelectedOptionId: encryptedSelectedOptionId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuizAnswersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({draftId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (draftId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.draftId,
                                referencedTable: $$QuizAnswersTableReferences
                                    ._draftIdTable(db),
                                referencedColumn: $$QuizAnswersTableReferences
                                    ._draftIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QuizAnswersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizAnswersTable,
      QuizAnswer,
      $$QuizAnswersTableFilterComposer,
      $$QuizAnswersTableOrderingComposer,
      $$QuizAnswersTableAnnotationComposer,
      $$QuizAnswersTableCreateCompanionBuilder,
      $$QuizAnswersTableUpdateCompanionBuilder,
      (QuizAnswer, $$QuizAnswersTableReferences),
      QuizAnswer,
      PrefetchHooks Function({bool draftId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DatabaseMetadataTableTableTableManager get databaseMetadataTable =>
      $$DatabaseMetadataTableTableTableManager(_db, _db.databaseMetadataTable);
  $$CachedLessonsTableTableManager get cachedLessons =>
      $$CachedLessonsTableTableManager(_db, _db.cachedLessons);
  $$QuizDraftsTableTableManager get quizDrafts =>
      $$QuizDraftsTableTableManager(_db, _db.quizDrafts);
  $$QuizAnswersTableTableManager get quizAnswers =>
      $$QuizAnswersTableTableManager(_db, _db.quizAnswers);
}
