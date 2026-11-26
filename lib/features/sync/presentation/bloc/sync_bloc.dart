import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sync_result.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/usecases/sync_engine.dart';
import 'sync_event.dart';
import 'sync_state.dart';

/// Manages submission outbox staging and bounded synchronization presentation lifecycle
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncRepository syncRepository;
  final ISyncEngine syncEngine;

  SyncBloc({required this.syncRepository, required this.syncEngine})
    : super(const SyncInitial()) {
    on<StageAndSyncRequested>(_onStageAndSyncRequested);
    on<SyncTriggered>(_onSyncTriggered);
    on<RecoverLeasesRequested>(_onRecoverLeasesRequested);
    on<ResetSync>(_onResetSync);
  }

  void _onResetSync(ResetSync event, Emitter<SyncState> emit) {
    emit(const SyncInitial());
  }

  Future<void> _onRecoverLeasesRequested(
    RecoverLeasesRequested event,
    Emitter<SyncState> emit,
  ) async {
    await syncRepository.recoverExpiredLeases();
  }

  Future<void> _onStageAndSyncRequested(
    StageAndSyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    emit(const SyncStaging());

    try {
      // 1. Atomically stage into SubmissionOutbox
      final staged = await syncRepository.stageSubmission(
        learnerId: event.learnerId,
        lessonId: event.lessonId,
      );

      emit(
        SyncInFlight(outboxId: staged.id, operationKey: staged.operationKey),
      );

      // 2. Execute bounded foreground synchronization attempt
      final result = await syncEngine.synchronize(learnerId: event.learnerId);
      _handleSyncResult(result, emit, stagedId: staged.id);
    } catch (e) {
      emit(SyncTransientFailure(message: e.toString()));
    }
  }

  Future<void> _onSyncTriggered(
    SyncTriggered event,
    Emitter<SyncState> emit,
  ) async {
    final result = await syncEngine.synchronize(learnerId: event.learnerId);
    _handleSyncResult(result, emit);
  }

  void _handleSyncResult(
    SyncResult result,
    Emitter<SyncState> emit, {
    String? stagedId,
  }) {
    switch (result.outcome) {
      case SyncOutcomeStatus.success:
        emit(
          SyncSuccess(
            outboxId: result.outboxId ?? stagedId ?? '',
            receiptId: result.receiptId ?? 'acknowledged',
          ),
        );
        break;
      case SyncOutcomeStatus.transientFailure:
        emit(
          SyncTransientFailure(
            message:
                result.errorMessage ??
                'Offline: submission safely preserved in outbox. Will retry when connected.',
            canRetry: true,
          ),
        );
        break;
      case SyncOutcomeStatus.blocked:
        emit(
          SyncBlocked(
            result.errorMessage ??
                'Submission blocked: content revision changed. Your draft has been preserved.',
          ),
        );
        break;
      case SyncOutcomeStatus.sessionInvalidated:
        emit(const SyncInitial());
        break;
      case SyncOutcomeStatus.budgetExhausted:
        emit(
          const SyncTransientFailure(
            message:
                'Sync time budget reached (10s). Submission is safely queued in the outbox.',
            canRetry: true,
          ),
        );
        break;
      case SyncOutcomeStatus.idle:
        break;
    }
  }
}
