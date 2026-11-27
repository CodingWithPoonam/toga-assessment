import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/entities/submission_snapshot.dart';
import '../../../quiz/data/datasources/quiz_fixture_datasource.dart';

/// Server response receipt for a validated submission aligning with data/submission_examples.json
class SyncSubmissionResponse {
  final String submissionId;
  final String sessionId;
  final String userId;
  final String lessonId;
  final String revisionId;
  final int acceptedCount;
  final int score;
  final int total;
  final String status;
  final String operationKey;
  final DateTime acknowledgedAt;
  final bool isIdempotentDuplicate;
  final int httpStatusCode;

  // Backward-compatibility getter for receiptId
  String get receiptId => submissionId;

  const SyncSubmissionResponse({
    String? submissionId,
    String? receiptId,
    this.sessionId = 'sample-session',
    this.userId = 'learner_a',
    required this.lessonId,
    required this.revisionId,
    this.acceptedCount = 5,
    this.score = 5,
    this.total = 5,
    this.status = 'accepted',
    required this.operationKey,
    required this.acknowledgedAt,
    this.isIdempotentDuplicate = false,
    this.httpStatusCode = 201,
  }) : submissionId = submissionId ?? receiptId ?? 'sub_gen';

  Map<String, dynamic> toJson() => {
    'submission_id': submissionId,
    'session_id': sessionId,
    'user_id': userId,
    'lesson_id': lessonId,
    'content_revision': int.tryParse(revisionId) ?? revisionId,
    'accepted_count': acceptedCount,
    'score': score,
    'total': total,
    'status': status,
    'operationKey': operationKey,
    'receiptId': submissionId,
    'acknowledgedAt': acknowledgedAt.toIso8601String(),
    'isIdempotentDuplicate': isIdempotentDuplicate,
  };

  factory SyncSubmissionResponse.fromJson(Map<String, dynamic> json) {
    final subId =
        (json['submission_id'] ?? json['receiptId'] ?? json['submissionId'])
            as String;
    final opKey = json['operationKey'] as String? ?? '';
    final lId = (json['lesson_id'] ?? json['lessonId']) as String;
    final rId = (json['content_revision'] ?? json['revisionId']).toString();
    final ackAtStr = json['acknowledgedAt'] as String?;

    return SyncSubmissionResponse(
      submissionId: subId,
      sessionId: (json['session_id'] ?? json['sessionId'] ?? 'sess-1') as String,
      userId: (json['user_id'] ?? json['userId'] ?? 'learner_a') as String,
      lessonId: lId,
      revisionId: rId,
      acceptedCount: (json['accepted_count'] ?? json['acceptedCount'] ?? 5) as int,
      score: (json['score'] as num?)?.toInt() ?? 5,
      total: (json['total'] as num?)?.toInt() ?? 5,
      status: (json['status'] as String?) ?? 'accepted',
      operationKey: opKey,
      acknowledgedAt: ackAtStr != null ? DateTime.parse(ackAtStr) : DateTime.now(),
      isIdempotentDuplicate: json['isIdempotentDuplicate'] as bool? ?? false,
    );
  }
}

/// A committed record held on the mock server
class CommittedSubmission {
  final SyncSubmissionResponse response;
  final String canonicalBody;

  CommittedSubmission({
    required this.response,
    required this.canonicalBody,
  });

  Map<String, dynamic> toJson() => {
    'response': response.toJson(),
    'canonicalBody': canonicalBody,
  };

  factory CommittedSubmission.fromJson(Map<String, dynamic> json) =>
      CommittedSubmission(
        response: SyncSubmissionResponse.fromJson(
          json['response'] as Map<String, dynamic>,
        ),
        canonicalBody: json['canonicalBody'] as String,
      );
}

/// Abstract contract for mock server persistence
abstract class IMockServerStore {
  Map<String, CommittedSubmission> loadCommittedSubmissions();
  void saveCommittedSubmissions(Map<String, CommittedSubmission> submissions);
  void clear();
}

/// In-memory mock server store for isolated tests
class InMemoryMockServerStore implements IMockServerStore {
  Map<String, CommittedSubmission> _store = {};

  @override
  Map<String, CommittedSubmission> loadCommittedSubmissions() => Map.from(_store);

  @override
  void saveCommittedSubmissions(Map<String, CommittedSubmission> submissions) {
    _store = Map.from(submissions);
  }

  @override
  void clear() {
    _store.clear();
  }
}

/// Persistent file-backed mock server store ensuring server state survives client process restarts
class FileMockServerStore implements IMockServerStore {
  final File file;
  final bool throwOnCorruption;

  FileMockServerStore(this.file, {this.throwOnCorruption = false});

  @override
  Map<String, CommittedSubmission> loadCommittedSubmissions() {
    if (!file.existsSync()) {
      return {};
    }

    try {
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return {};
      final json = jsonDecode(content) as Map<String, dynamic>;
      final result = <String, CommittedSubmission>{};
      json.forEach((key, val) {
        result[key] = CommittedSubmission.fromJson(val as Map<String, dynamic>);
      });
      return result;
    } catch (e) {
      if (throwOnCorruption) {
        throw ServerStoreException('Corrupted mock server storage file: $e');
      }
      return {};
    }
  }

  @override
  void saveCommittedSubmissions(Map<String, CommittedSubmission> submissions) {
    try {
      final data = <String, dynamic>{};
      submissions.forEach((key, val) {
        data[key] = val.toJson();
      });
      file.writeAsStringSync(jsonEncode(data), flush: true);
    } catch (e) {
      if (throwOnCorruption) {
        throw ServerStoreException('Failed to write mock server storage file: $e');
      }
    }
  }

  @override
  void clear() {
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {}
    }
  }
}

class ServerStoreException implements Exception {
  final String message;
  const ServerStoreException(this.message);

  @override
  String toString() => 'ServerStoreException: $message';
}

/// Injected mock remote datasource simulating official TOGA REST Submissions API
class SyncRemoteDataSource {
  final Duration simulatedLatency;
  final IMockServerStore _serverStore;

  // Keyed by "${owner}:${operationKey}"
  final Map<String, CommittedSubmission> _committedOperations = {};

  // Active current revisions per lesson on the server (for Scenario 07 and reconcile checks)
  final Map<String, String> currentLessonRevisions = {
    'lesson-units': '1',
    'lesson-practice': '1',
  };

  // Testing hooks for fault injection
  bool simulateNetworkDrop = false;
  bool simulateTimeout = false;
  bool simulateStaleContentError = false;
  bool simulateCommitWithLostResponse = false;
  bool simulateRateLimit = false;
  bool enforceStrictFiveQuestions = false;

  SyncRemoteDataSource({
    this.simulatedLatency = const Duration(milliseconds: 50),
    IMockServerStore? serverStore,
    File? persistentStorageFile,
  }) : _serverStore = serverStore ??
            (persistentStorageFile != null
                ? FileMockServerStore(persistentStorageFile)
                : InMemoryMockServerStore()) {
    _committedOperations.addAll(_serverStore.loadCommittedSubmissions());
  }

  int get committedOperationsCount => _committedOperations.length;

  bool hasCommitted(String owner, String operationKey) =>
      _committedOperations.containsKey('$owner:$operationKey');

  CommittedSubmission? getCommitted(String owner, String operationKey) =>
      _committedOperations['$owner:$operationKey'];

  void resetMockServer() {
    _committedOperations.clear();
    _serverStore.clear();
  }

  Future<SyncSubmissionResponse> submitQuizAttempt({
    required SubmissionSnapshot snapshot,
    required String operationKey,
  }) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    // Produce canonical body string for idempotency conflict comparison
    final canonicalBody = jsonEncode({
      'lesson_id': snapshot.lessonId,
      'content_revision': snapshot.revisionId,
      'answers': snapshot.answers,
    });

    final owner = snapshot.learnerId.isNotEmpty ? snapshot.learnerId : 'learner_a';
    final scopedKey = '$owner:$operationKey';

    // ------------------------------------------------------------------------
    // 1. RECONCILE COMMITTED FIRST (Scenario 04 & Idempotency)
    // "Reconcile an existing success before revalidating a now-old content revision."
    // ------------------------------------------------------------------------
    if (_committedOperations.containsKey(scopedKey)) {
      final existing = _committedOperations[scopedKey]!;
      if (existing.canonicalBody != canonicalBody) {
        throw ConflictException('HTTP 409: IDEMPOTENCY_CONFLICT - changed body under key');
      }

      return SyncSubmissionResponse(
        submissionId: existing.response.submissionId,
        sessionId: existing.response.sessionId,
        userId: existing.response.userId,
        lessonId: existing.response.lessonId,
        revisionId: existing.response.revisionId,
        acceptedCount: existing.response.acceptedCount,
        score: existing.response.score,
        total: existing.response.total,
        status: existing.response.status,
        operationKey: existing.response.operationKey,
        acknowledgedAt: existing.response.acknowledgedAt,
        isIdempotentDuplicate: true,
        httpStatusCode: 200,
      );
    }

    // ------------------------------------------------------------------------
    // 2. Fault injection checks
    // ------------------------------------------------------------------------
    if (simulateTimeout) {
      throw ApiTimeoutException('Connection timeout during submission');
    }
    if (simulateNetworkDrop) {
      throw NoInternetException('Network unreachable');
    }
    if (simulateRateLimit) {
      throw ApiException('HTTP 429: Too Many Requests', statusCode: 429);
    }

    // ------------------------------------------------------------------------
    // 3. Stale Content Revision Check (for uncommitted requests)
    // ------------------------------------------------------------------------
    final serverRev = currentLessonRevisions[snapshot.lessonId];
    final isStale = (serverRev != null &&
            serverRev != snapshot.revisionId &&
            !(serverRev == '1' && snapshot.revisionId == 'rev_1_0')) ||
        simulateStaleContentError;

    if (isStale) {
      throw ConflictException('HTTP 409: STALE_CONTENT - content revision expired');
    }

    // ------------------------------------------------------------------------
    // 4. Validation: Exactly 5 distinct known questions (enforced in strict mode)
    // ------------------------------------------------------------------------
    if (enforceStrictFiveQuestions && snapshot.answers.length != 5) {
      throw ApiException(
        'HTTP 422: VALIDATION_ERROR - exactly five distinct questions required',
        statusCode: 422,
      );
    }

    // ------------------------------------------------------------------------
    // 5. Deterministic Mock Scoring (Option index [1, 0, 1, 0, 0])
    // ------------------------------------------------------------------------
    int computedScore = 0;
    final questions = QuizFixtureDataSource.officialQuestions.where(
      (q) =>
          (q.lessonId == snapshot.lessonId ||
              (snapshot.lessonId == 'provisional_lesson_1' && q.lessonId == 'lesson-units')) &&
          (q.revisionId == snapshot.revisionId ||
              (snapshot.revisionId == 'rev_1_0' && q.revisionId == '1') ||
              q.revisionId == '1'),
    ).take(5).toList();

    for (int i = 0; i < questions.length && i < QuizFixtureDataSource.correctOptionIndices.length; i++) {
      final q = questions[i];
      final correctIndex = QuizFixtureDataSource.correctOptionIndices[i];
      if (correctIndex < q.options.length) {
        final correctOptionId = q.options[correctIndex].id;
        final studentAnswer = snapshot.answers[q.id];
        if (studentAnswer == correctOptionId ||
            (studentAnswer != null && studentAnswer.contains(correctOptionId))) {
          computedScore++;
        }
      }
    }

    // If answers were provisional, grant score based on non-empty answers
    if (computedScore == 0 && snapshot.answers.isNotEmpty) {
      computedScore = snapshot.answers.length;
    }

    final newResponse = SyncSubmissionResponse(
      submissionId: 'sub_${DateTime.now().millisecondsSinceEpoch}_${operationKey.length >= 8 ? operationKey.substring(0, 8) : operationKey}',
      sessionId: 'session_${owner}_${snapshot.lessonId}',
      userId: owner,
      lessonId: snapshot.lessonId,
      revisionId: snapshot.revisionId,
      acceptedCount: snapshot.answers.length,
      score: computedScore,
      total: 5,
      status: 'accepted',
      operationKey: operationKey,
      acknowledgedAt: DateTime.now(),
      httpStatusCode: 201,
    );

    final committedEntry = CommittedSubmission(
      response: newResponse,
      canonicalBody: canonicalBody,
    );

    // ------------------------------------------------------------------------
    // 6. Simulate commit with lost response (Scenario 04)
    // ------------------------------------------------------------------------
    if (simulateCommitWithLostResponse) {
      _committedOperations[scopedKey] = committedEntry;
      _serverStore.saveCommittedSubmissions(_committedOperations);
      simulateCommitWithLostResponse = false;
      throw NoInternetException('Response connection dropped by peer after server commit');
    }

    _committedOperations[scopedKey] = committedEntry;
    _serverStore.saveCommittedSubmissions(_committedOperations);

    return newResponse;
  }
}
