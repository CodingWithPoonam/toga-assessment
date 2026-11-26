import 'package:equatable/equatable.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class StageAndSyncRequested extends SyncEvent {
  final String learnerId;
  final String lessonId;

  const StageAndSyncRequested({
    required this.learnerId,
    required this.lessonId,
  });

  @override
  List<Object?> get props => [learnerId, lessonId];
}

class SyncTriggered extends SyncEvent {
  final String learnerId;

  const SyncTriggered({required this.learnerId});

  @override
  List<Object?> get props => [learnerId];
}

class RecoverLeasesRequested extends SyncEvent {
  const RecoverLeasesRequested();
}

class ResetSync extends SyncEvent {
  const ResetSync();
}
