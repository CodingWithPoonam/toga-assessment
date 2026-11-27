import 'package:equatable/equatable.dart';

enum MigrationStatus {
  success,
  noDataFound,
  alreadyMigrated,
  ownerMismatch,
  unauthenticated,
  corruptedData,
  validationFailed,
  storageFailure,
}

class MigrationResult extends Equatable {
  final MigrationStatus status;
  final String? message;
  final String? migratedLessonId;
  final int migratedAnswersCount;

  const MigrationResult({
    required this.status,
    this.message,
    this.migratedLessonId,
    this.migratedAnswersCount = 0,
  });

  bool get isSuccess =>
      status == MigrationStatus.success ||
      status == MigrationStatus.alreadyMigrated;

  @override
  List<Object?> get props => [
    status,
    message,
    migratedLessonId,
    migratedAnswersCount,
  ];
}
