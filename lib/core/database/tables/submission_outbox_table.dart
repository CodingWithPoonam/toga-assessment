import 'package:drift/drift.dart';

/// Table representing the durable submission outbox for offline-first synchronization
@TableIndex(name: 'idx_outbox_learner_status', columns: {#learnerId, #status})
@TableIndex(
  name: 'idx_outbox_status_eligible',
  columns: {#status, #nextEligibleAttemptAt},
)
@TableIndex(name: 'idx_outbox_lease_expires', columns: {#leaseExpiresAt})
class SubmissionOutbox extends Table {
  TextColumn get id => text()();
  TextColumn get learnerId => text()();
  TextColumn get lessonId => text()();
  TextColumn get revisionId => text()();
  TextColumn get operationKey => text().unique()();
  TextColumn get encryptedPayload => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptedAt => dateTime().nullable()();
  DateTimeColumn get nextEligibleAttemptAt => dateTime().nullable()();
  TextColumn get lastFailureCategory => text().nullable()();
  DateTimeColumn get leaseExpiresAt => dateTime().nullable()();
  TextColumn get serverAcknowledgement => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
