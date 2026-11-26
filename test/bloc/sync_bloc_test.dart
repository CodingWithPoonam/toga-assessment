import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toga_assessment/features/sync/domain/entities/outbox_enums.dart';
import 'package:toga_assessment/features/sync/domain/entities/submission_record.dart';
import 'package:toga_assessment/features/sync/domain/entities/sync_result.dart';
import 'package:toga_assessment/features/sync/domain/repositories/sync_repository.dart';
import 'package:toga_assessment/features/sync/domain/usecases/sync_engine.dart';
import 'package:toga_assessment/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:toga_assessment/features/sync/presentation/bloc/sync_event.dart';
import 'package:toga_assessment/features/sync/presentation/bloc/sync_state.dart';

class MockSyncRepository extends Mock implements SyncRepository {}

class MockSyncEngine extends Mock implements ISyncEngine {}

void main() {
  late MockSyncRepository mockSyncRepository;
  late MockSyncEngine mockSyncEngine;
  late SyncBloc syncBloc;

  final sampleStagedRecord = SubmissionRecord(
    id: 'outbox_test_1',
    learnerId: 'learner-a',
    lessonId: 'provisional_lesson_1',
    revisionId: 'rev_1_0',
    operationKey: 'op_key_123',
    encryptedPayload: 'encrypted_payload_bytes',
    status: OutboxStatus.pending,
    attemptCount: 0,
    createdAt: DateTime.now(),
  );

  setUp(() {
    mockSyncRepository = MockSyncRepository();
    mockSyncEngine = MockSyncEngine();
    syncBloc = SyncBloc(
      syncRepository: mockSyncRepository,
      syncEngine: mockSyncEngine,
    );
  });

  tearDown(() {
    syncBloc.close();
  });

  group('SyncBloc', () {
    test('initial state is SyncInitial', () {
      expect(syncBloc.state, equals(const SyncInitial()));
    });

    blocTest<SyncBloc, SyncState>(
      'StageAndSyncRequested emits [SyncStaging, SyncInFlight, SyncSuccess] on successful sync',
      build: () {
        when(
          () => mockSyncRepository.stageSubmission(
            learnerId: 'learner-a',
            lessonId: 'provisional_lesson_1',
          ),
        ).thenAnswer((_) async => sampleStagedRecord);

        when(
          () => mockSyncEngine.synchronize(learnerId: 'learner-a'),
        ).thenAnswer(
          (_) async => SyncResult.success(
            outboxId: 'outbox_test_1',
            operationKey: 'op_key_123',
            receiptId: 'receipt_789',
            elapsed: const Duration(milliseconds: 150),
          ),
        );

        return syncBloc;
      },
      act: (bloc) => bloc.add(
        const StageAndSyncRequested(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
        ),
      ),
      expect: () => [
        const SyncStaging(),
        const SyncInFlight(
          outboxId: 'outbox_test_1',
          operationKey: 'op_key_123',
        ),
        const SyncSuccess(outboxId: 'outbox_test_1', receiptId: 'receipt_789'),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'StageAndSyncRequested emits [SyncStaging, SyncInFlight, SyncTransientFailure] when network fails',
      build: () {
        when(
          () => mockSyncRepository.stageSubmission(
            learnerId: 'learner-a',
            lessonId: 'provisional_lesson_1',
          ),
        ).thenAnswer((_) async => sampleStagedRecord);

        when(
          () => mockSyncEngine.synchronize(learnerId: 'learner-a'),
        ).thenAnswer(
          (_) async => SyncResult.transientFailure(
            outboxId: 'outbox_test_1',
            message: 'Network unreachable',
            elapsed: const Duration(milliseconds: 200),
          ),
        );

        return syncBloc;
      },
      act: (bloc) => bloc.add(
        const StageAndSyncRequested(
          learnerId: 'learner-a',
          lessonId: 'provisional_lesson_1',
        ),
      ),
      expect: () => [
        const SyncStaging(),
        const SyncInFlight(
          outboxId: 'outbox_test_1',
          operationKey: 'op_key_123',
        ),
        const SyncTransientFailure(
          message: 'Network unreachable',
          canRetry: true,
        ),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'ResetSync resets state to SyncInitial',
      build: () => syncBloc,
      seed: () => const SyncTransientFailure(message: 'error'),
      act: (bloc) => bloc.add(const ResetSync()),
      expect: () => [const SyncInitial()],
    );
  });
}
