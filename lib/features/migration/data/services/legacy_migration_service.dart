import 'dart:convert';
import 'package:toga_assessment/features/quiz/data/datasources/quiz_fixture_datasource.dart';
import 'package:toga_assessment/features/quiz/data/datasources/quiz_local_datasource.dart';
import 'package:toga_assessment/features/migration/domain/entities/migration_result.dart';
import 'package:toga_assessment/features/migration/data/datasources/legacy_migration_source.dart';

/// Service responsible for migrating plaintext legacy progress (v1) into encrypted Drift SQLite
class LegacyMigrationService {
  final ILegacyMigrationSource source;
  final QuizLocalDataSource quizLocalDataSource;
  final QuizFixtureDataSource quizFixtureDataSource;

  LegacyMigrationService({
    required this.source,
    required this.quizLocalDataSource,
    required this.quizFixtureDataSource,
  });

  /// Migrates legacy private data for the authenticated learner.
  ///
  /// Invariants:
  /// 1. Plaintext legacy refresh token is NEVER treated as authentication.
  /// 2. Authenticated learner must be explicitly supplied and verified against legacy record owner.
  /// 3. Content revision, question IDs, and answer options must be validated against fixture schema.
  /// 4. Plaintext legacy data is deleted ONLY after encrypted persistence succeeds.
  /// 5. Execution is idempotent; calling multiple times will not duplicate or corrupt state.
  Future<MigrationResult> migrate({
    required String? authenticatedLearnerId,
  }) async {
    // Invariant 1 & 2: Reauthentication required
    if (authenticatedLearnerId == null || authenticatedLearnerId.trim().isEmpty) {
      return const MigrationResult(
        status: MigrationStatus.unauthenticated,
        message: 'Reauthentication required: no active authenticated session',
      );
    }

    // Step 1: Read raw legacy data
    final rawData = await source.readRawLegacyData();
    if (rawData == null || rawData.trim().isEmpty) {
      return const MigrationResult(
        status: MigrationStatus.noDataFound,
        message: 'No legacy data found in source adapter',
      );
    }

    // Step 2: Parse legacy JSON safely
    Map<String, dynamic> legacyJson;
    try {
      final decoded = jsonDecode(rawData);
      if (decoded is! Map<String, dynamic>) {
        return const MigrationResult(
          status: MigrationStatus.corruptedData,
          message: 'Malformed legacy payload: root is not a JSON object',
        );
      }
      legacyJson = decoded;
    } catch (e) {
      return MigrationResult(
        status: MigrationStatus.corruptedData,
        message: 'Malformed legacy JSON format: $e',
      );
    }

    // Step 3: Validate draft structure
    final draft = legacyJson['draft'];
    if (draft is! Map<String, dynamic>) {
      return const MigrationResult(
        status: MigrationStatus.corruptedData,
        message: 'Missing or corrupt draft object in legacy record',
      );
    }

    final owner = draft['owner'] as String?;
    if (owner == null || owner.trim().isEmpty) {
      return const MigrationResult(
        status: MigrationStatus.corruptedData,
        message: 'Corrupted legacy draft: missing owner',
      );
    }

    // Invariant 2: Verify authenticated owner matches legacy record owner
    if (owner != authenticatedLearnerId) {
      return MigrationResult(
        status: MigrationStatus.ownerMismatch,
        message:
            'Tenant boundary violation: authenticated as $authenticatedLearnerId but legacy draft belongs to $owner',
      );
    }

    final lessonId = draft['lesson_id'] as String?;
    final rawRevision = draft['content_revision'];
    final revisionId = rawRevision?.toString();

    if (lessonId == null || lessonId.trim().isEmpty || revisionId == null) {
      return const MigrationResult(
        status: MigrationStatus.corruptedData,
        message: 'Corrupted legacy draft: missing lesson_id or content_revision',
      );
    }

    // Step 4: Validate lesson ID, revision, and questions against official fixtures
    final officialQuestions =
        await quizFixtureDataSource.getQuestionsForLesson(lessonId);
    if (officialQuestions.isEmpty) {
      return MigrationResult(
        status: MigrationStatus.validationFailed,
        message: 'Validation failed: Unknown lesson_id "$lessonId"',
      );
    }

    final revisionQuestions = officialQuestions
        .where((q) => q.revisionId == revisionId)
        .toList();
    if (revisionQuestions.isEmpty) {
      return MigrationResult(
        status: MigrationStatus.validationFailed,
        message:
            'Validation failed: Revision "$revisionId" not valid for lesson "$lessonId"',
      );
    }

    // Validate position
    final position = draft['position'] as int? ?? 0;
    if (position < 0 || position > revisionQuestions.length) {
      return MigrationResult(
        status: MigrationStatus.validationFailed,
        message: 'Validation failed: Invalid saved position $position (max ${revisionQuestions.length})',
      );
    }

    // Validate answers: never invent or silently accept unknown questions or options
    final answersRaw = draft['answers'];
    if (answersRaw is! Map) {
      return const MigrationResult(
        status: MigrationStatus.corruptedData,
        message: 'Corrupted legacy draft: answers is not a map',
      );
    }

    final validatedAnswers = <String, String>{};
    for (final entry in answersRaw.entries) {
      final qId = entry.key.toString();
      final optId = entry.value.toString();

      final question = revisionQuestions.cast<dynamic>().firstWhere(
        (q) => q.id == qId,
        orElse: () => null,
      );
      if (question == null) {
        return MigrationResult(
          status: MigrationStatus.validationFailed,
          message: 'Validation failed: Question "$qId" not found in lesson "$lessonId" revision "$revisionId"',
        );
      }

      final option = question.options.cast<dynamic>().firstWhere(
        (o) => o.id == optId,
        orElse: () => null,
      );
      if (option == null) {
        return MigrationResult(
          status: MigrationStatus.validationFailed,
          message: 'Validation failed: Option "$optId" not valid for question "$qId"',
        );
      }

      validatedAnswers[qId] = optId;
    }

    // Step 5: Check idempotency (has this draft already been persisted?)
    final existingDraft = await quizLocalDataSource.getDraft(
      learnerId: authenticatedLearnerId,
      lessonId: lessonId,
    );

    if (existingDraft != null &&
        existingDraft.revisionId == revisionId &&
        _mapsEqual(existingDraft.answers, validatedAnswers)) {
      // Already safely migrated; delete plaintext source and return alreadyMigrated
      await source.deleteLegacyData();
      return MigrationResult(
        status: MigrationStatus.alreadyMigrated,
        message: 'Draft was already migrated and verified',
        migratedLessonId: lessonId,
        migratedAnswersCount: validatedAnswers.length,
      );
    }

    // Step 6: Atomic encrypted persistence into Drift SQLite
    try {
      await quizLocalDataSource.saveDraftAtomically(
        learnerId: authenticatedLearnerId,
        lessonId: lessonId,
        revisionId: revisionId,
        currentQuestionIndex: position,
        answers: validatedAnswers,
      );
    } catch (e) {
      // Invariant 4: Plaintext legacy source retained when encrypted persistence fails
      return MigrationResult(
        status: MigrationStatus.storageFailure,
        message: 'Encrypted persistence failed: $e',
      );
    }

    // Step 7: Remove plaintext legacy source ONLY AFTER successful encrypted persistence
    try {
      await source.deleteLegacyData();
    } catch (e) {
      return MigrationResult(
        status: MigrationStatus.storageFailure,
        message: 'Encrypted persistence succeeded but plaintext deletion failed: $e',
        migratedLessonId: lessonId,
        migratedAnswersCount: validatedAnswers.length,
      );
    }

    return MigrationResult(
      status: MigrationStatus.success,
      message: 'Successfully migrated legacy progress to encrypted SQLite storage',
      migratedLessonId: lessonId,
      migratedAnswersCount: validatedAnswers.length,
    );
  }

  bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (b[key] != a[key]) return false;
    }
    return true;
  }
}
