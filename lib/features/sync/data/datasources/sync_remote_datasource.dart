import 'dart:async';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/entities/submission_snapshot.dart';

/// Server response receipt for a validated submission
class SyncSubmissionResponse {
  final String receiptId;
  final String operationKey;
  final String lessonId;
  final String revisionId;
  final DateTime acknowledgedAt;
  final bool isIdempotentDuplicate;

  const SyncSubmissionResponse({
    required this.receiptId,
    required this.operationKey,
    required this.lessonId,
    required this.revisionId,
    required this.acknowledgedAt,
    this.isIdempotentDuplicate = false,
  });

  Map<String, dynamic> toJson() => {
    'receiptId': receiptId,
    'operationKey': operationKey,
    'lessonId': lessonId,
    'revisionId': revisionId,
    'acknowledgedAt': acknowledgedAt.toIso8601String(),
    'isIdempotentDuplicate': isIdempotentDuplicate,
  };

  factory SyncSubmissionResponse.fromJson(Map<String, dynamic> json) =>
      SyncSubmissionResponse(
        receiptId: json['receiptId'] as String,
        operationKey: json['operationKey'] as String,
        lessonId: json['lessonId'] as String,
        revisionId: json['revisionId'] as String,
        acknowledgedAt: DateTime.parse(json['acknowledgedAt'] as String),
        isIdempotentDuplicate: json['isIdempotentDuplicate'] as bool? ?? false,
      );
}

/// PROVISIONAL_DEVELOPMENT_FIXTURE_NOT_OFFICIAL_AIRMAN_DATA
/// Isolated mock remote data source simulating remote submission sync API
class SyncRemoteDataSource {
  final Duration simulatedLatency;
  final Map<String, SyncSubmissionResponse> _committedOperations = {};

  // Testing hooks for fault injection
  bool simulateNetworkDrop = false;
  bool simulateTimeout = false;
  bool simulateStaleContentError = false;
  bool simulateCommitWithLostResponse = false;
  bool simulateRateLimit = false;

  SyncRemoteDataSource({
    this.simulatedLatency = const Duration(milliseconds: 60),
  });

  Future<SyncSubmissionResponse> submitQuizAttempt({
    required SubmissionSnapshot snapshot,
    required String operationKey,
  }) async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }

    // 1. Fault injection checks
    if (simulateTimeout) {
      throw ApiTimeoutException('Connection timeout during submission');
    }

    if (simulateNetworkDrop) {
      throw NoInternetException('Network unreachable');
    }

    if (simulateRateLimit) {
      throw ApiException('HTTP 429: Too Many Requests', statusCode: 429);
    }

    if (simulateStaleContentError) {
      throw ConflictException(
        'Server rejected submission: lesson revision has changed (stale_content)',
      );
    }

    // 2. Check idempotency: if operationKey was already committed, return cached receipt
    if (_committedOperations.containsKey(operationKey)) {
      final cached = _committedOperations[operationKey]!;
      return SyncSubmissionResponse(
        receiptId: cached.receiptId,
        operationKey: cached.operationKey,
        lessonId: cached.lessonId,
        revisionId: cached.revisionId,
        acknowledgedAt: cached.acknowledgedAt,
        isIdempotentDuplicate: true,
      );
    }

    // 3. Simulate commit where response is lost before reaching client
    if (simulateCommitWithLostResponse) {
      final receipt = SyncSubmissionResponse(
        receiptId: 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        operationKey: operationKey,
        lessonId: snapshot.lessonId,
        revisionId: snapshot.revisionId,
        acknowledgedAt: DateTime.now(),
      );
      _committedOperations[operationKey] = receipt;
      simulateCommitWithLostResponse = false; // Reset fault
      throw NoInternetException('Response connection dropped by peer');
    }

    // 4. Normal successful acceptance
    final response = SyncSubmissionResponse(
      receiptId: 'receipt_${DateTime.now().millisecondsSinceEpoch}',
      operationKey: operationKey,
      lessonId: snapshot.lessonId,
      revisionId: snapshot.revisionId,
      acknowledgedAt: DateTime.now(),
    );

    _committedOperations[operationKey] = response;
    return response;
  }
}
