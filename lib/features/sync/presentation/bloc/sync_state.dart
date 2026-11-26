import 'package:equatable/equatable.dart';

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {
  const SyncInitial();
}

class SyncStaging extends SyncState {
  const SyncStaging();
}

class SyncInFlight extends SyncState {
  final String outboxId;
  final String operationKey;

  const SyncInFlight({required this.outboxId, required this.operationKey});

  @override
  List<Object?> get props => [outboxId, operationKey];
}

class SyncSuccess extends SyncState {
  final String outboxId;
  final String receiptId;
  final bool isOfflineQueued;

  const SyncSuccess({
    required this.outboxId,
    required this.receiptId,
    this.isOfflineQueued = false,
  });

  @override
  List<Object?> get props => [outboxId, receiptId, isOfflineQueued];
}

class SyncTransientFailure extends SyncState {
  final String message;
  final bool canRetry;

  const SyncTransientFailure({required this.message, this.canRetry = true});

  @override
  List<Object?> get props => [message, canRetry];
}

class SyncBlocked extends SyncState {
  final String reason;

  const SyncBlocked(this.reason);

  @override
  List<Object?> get props => [reason];
}

class SyncAuthRequired extends SyncState {
  const SyncAuthRequired();
}
