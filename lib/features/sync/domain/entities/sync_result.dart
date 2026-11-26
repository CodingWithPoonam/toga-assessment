import 'package:equatable/equatable.dart';

enum SyncOutcomeStatus {
  idle,
  success,
  transientFailure,
  blocked,
  sessionInvalidated,
  budgetExhausted,
}

/// Result of a bounded foreground synchronization run
class SyncResult extends Equatable {
  final SyncOutcomeStatus outcome;
  final String? outboxId;
  final String? operationKey;
  final String? receiptId;
  final String? errorMessage;
  final Duration elapsed;
  final int processedCount;

  const SyncResult({
    required this.outcome,
    this.outboxId,
    this.operationKey,
    this.receiptId,
    this.errorMessage,
    this.elapsed = Duration.zero,
    this.processedCount = 0,
  });

  factory SyncResult.idle() =>
      const SyncResult(outcome: SyncOutcomeStatus.idle);

  factory SyncResult.success({
    required String outboxId,
    required String operationKey,
    required String receiptId,
    required Duration elapsed,
  }) => SyncResult(
    outcome: SyncOutcomeStatus.success,
    outboxId: outboxId,
    operationKey: operationKey,
    receiptId: receiptId,
    elapsed: elapsed,
    processedCount: 1,
  );

  factory SyncResult.transientFailure({
    required String outboxId,
    required String message,
    required Duration elapsed,
  }) => SyncResult(
    outcome: SyncOutcomeStatus.transientFailure,
    outboxId: outboxId,
    errorMessage: message,
    elapsed: elapsed,
  );

  factory SyncResult.blocked({
    required String outboxId,
    required String reason,
    required Duration elapsed,
  }) => SyncResult(
    outcome: SyncOutcomeStatus.blocked,
    outboxId: outboxId,
    errorMessage: reason,
    elapsed: elapsed,
  );

  factory SyncResult.sessionInvalidated() => const SyncResult(
    outcome: SyncOutcomeStatus.sessionInvalidated,
    errorMessage: 'Active session changed during synchronization',
  );

  factory SyncResult.budgetExhausted({required Duration elapsed}) => SyncResult(
    outcome: SyncOutcomeStatus.budgetExhausted,
    errorMessage: 'Foreground synchronization budget exceeded 10 seconds',
    elapsed: elapsed,
  );

  @override
  List<Object?> get props => [
    outcome,
    outboxId,
    operationKey,
    receiptId,
    errorMessage,
    elapsed,
    processedCount,
  ];
}
