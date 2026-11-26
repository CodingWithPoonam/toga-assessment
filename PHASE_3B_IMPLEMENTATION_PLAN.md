# AIRMAN TOGA — Phase 3B Implementation Plan
## Durable Submission Outbox & Synchronization Engine

*Created: November 2026*
*Author: Principal Flutter Architect*
*Baseline Git Commit: `36bac64`*

---

## 1. Executive Inspection & Baseline Audit

### 1.1 Existing Architecture & Technology Baseline
- **Flutter & Dart SDK**: Flutter 3.44.2 / Dart 3.12.2.
- **State Management & DI**: `flutter_bloc` 9.1.2, `get_it` 8.3.0.
- **Persistence**: Drift 2.34.4 / SQLite (`toga_app.sqlite` running in background thread via `NativeDatabase.createInBackground`).
- **Security & Cryptography**: `cryptography` 2.9.0 (AES-GCM-256 with Authenticated Additional Data), `flutter_secure_storage` 9.2.4.
- **Networking**: `dio` 5.11.1 with `AuthInterceptor`.
- **Navigation**: `go_router` 14.8.1 with `AuthRouterNotifier` authentication guards.
- **Baseline Verification**: All **62 existing unit, BLoC, and widget tests passing** cleanly; Android debug APK compiling without errors.

### 1.2 Inspection of Existing Subsystems
1. **`AppDatabase` (Current schemaVersion: 2)**:
   - Tables: `DatabaseMetadataTable`, `CachedLessons`, `QuizDrafts`, `QuizAnswers`.
   - Foreign keys: Enforced at connection time (`PRAGMA foreign_keys = ON;`).
   - `QuizDrafts`: Contains `id`, `learnerId`, `lessonId`, `revisionId`, `currentQuestionIndex`, `isSubmitted` (Boolean), `updatedAt`.
   - `QuizAnswers`: References `QuizDrafts(id)` with cascading delete. Plaintext option is never stored; encrypted with AES-GCM-256.
2. **`IEncryptionService` & `AesGcmEncryptionService`**:
   - Master key: 256-bit symmetric key persisted as Base64 in secure storage.
   - Nonce: Cryptographically random 12-byte nonce generated freshly per encryption.
   - MAC: 16-byte Poly1305 authentication tag appended; throws `SecurityException` upon tampering.
   - AAD: Accepts `associatedData` to cryptographically bind ciphertext to its database record.
3. **`ISessionManager` & Session Lifecycle**:
   - Access token: Resides strictly in volatile memory.
   - Refresh token & active learner ID: Stored in platform keychain/Keystore.
   - `sessionGeneration`: Ephemeral monotonicity counter incremented on login, switch, or logout to guard against asynchronous race conditions.
4. **`QuizRepository` & `QuizRepositoryImpl`**:
   - Explicit `learnerId` parameter on all draft methods with active session validation (`_validateLearnerSession`).
   - Revision pinning check: `isRevisionCurrent`.

---

## 2. Phase 3B Component Specifications

### 2.1 RFC 4122 v4 UUID Generator (`lib/core/utils/uuid_generator.dart`)
- Generates cryptographically secure, random RFC 4122 Version 4 UUIDs using `Random.secure()`.
- Zero additional dependencies to preserve lockfile integrity.
- Used for `SubmissionOutbox.id` and the immutable `operationKey`.

### 2.2 Database Migration: Schema v2 &rarr; v3
1. **`SubmissionOutbox` Table** (`lib/core/database/tables/submission_outbox_table.dart`):
   - `id`: TextColumn (UUID PK).
   - `learnerId`: TextColumn (indexed).
   - `lessonId`: TextColumn.
   - `revisionId`: TextColumn (immutable content revision).
   - `operationKey`: TextColumn (UUID, unique constraint).
   - `encryptedPayload`: TextColumn (AES-GCM encrypted snapshot).
   - `status`: TextColumn (typed enum: `pending`, `in_flight`, `completed`, `blocked`, `retry_scheduled`).
   - `attemptCount`: IntColumn (default 0).
   - `createdAt`: DateTimeColumn.
   - `lastAttemptedAt`: DateTimeColumn (nullable).
   - `nextEligibleAttemptAt`: DateTimeColumn (nullable, indexed).
   - `lastFailureCategory`: TextColumn (nullable: `timeout`, `network`, `auth`, `stale_content`, `validation`, `server_error`).
   - `leaseExpiresAt`: DateTimeColumn (nullable, indexed).
   - `serverAcknowledgement`: TextColumn (nullable JSON receipt).
   - Table indices: `(learnerId, status)`, `(status, nextEligibleAttemptAt)`, `(leaseExpiresAt)`.
2. **`QuizDrafts` Draft Status Migration**:
   - Add `draftStatus` column (`in_progress`, `staged`, `acknowledged`, `blocked`).
   - In `onUpgrade`: Migrate existing boolean `isSubmitted == false` to `in_progress`. Existing `isSubmitted == true` is migrated to `staged` (safe recoverable state, since an unacknowledged submission must be verified with the server).
   - All existing lessons, drafts, and encrypted answers are 100% preserved.

### 2.3 Immutable Submission Snapshot & Canonical AAD
- **Snapshot Payload**:
  ```json
  {
    "operationKey": "UUID",
    "learnerId": "learner-a",
    "lessonId": "provisional_lesson_1",
    "revisionId": "rev_1_0",
    "answers": { "q1": "opt_1c", ... },
    "stagedAt": "2026-11-26T23:15:00.000Z"
  }
  ```
- **Canonical AAD**:
  Lexicographically ordered canonical JSON string:
  ```json
  {"learnerId":"learner-a","lessonId":"provisional_lesson_1","operationKey":"UUID","revisionId":"rev_1_0"}
  ```
  Unambiguous, tamper-evident, immune to delimiter collisions.

### 2.4 Atomic Staging Transaction
Executed inside `database.transaction(...)`:
1. Validate draft exists and `draft.learnerId == sessionManager.activeLearnerId`.
2. Verify draft has at least one answered question and is eligible for staging (`in_progress` or retryable).
3. Verify `draft.revisionId` is retained without silent substitution.
4. Construct immutable `SubmissionSnapshot`.
5. Generate fresh RFC 4122 v4 UUID `operationKey`.
6. Compute canonical AAD and encrypt snapshot via `IEncryptionService`.
7. Insert `SubmissionOutbox` record (`status: pending`, `attemptCount: 0`).
8. Update `QuizDrafts`: set `draftStatus: staged`, `updatedAt: now`.
9. Commit atomically. If any error occurs, all changes roll back.
10. Draft is preserved in SQLite (never deleted at staging).

### 2.5 Bounded Foreground Sync Engine (`ISyncEngine` / `SyncEngine`)
- **Tenant Scope Guard**: Queries outbox strictly by `learnerId == sessionManager.activeLearnerId`. Learner B cannot claim or process Learner A's records.
- **Atomic Lease Claim**:
  ```sql
  UPDATE submission_outbox
  SET status = 'in_flight', leaseExpiresAt = now + 60s, lastAttemptedAt = now, attemptCount = attemptCount + 1
  WHERE id = :id AND status IN ('pending', 'retry_scheduled')
  ```
  Guarantees two concurrent triggers cannot claim the same record.
- **Budget Ceiling**:
  - Maximum 3 attempts per submission.
  - Maximum 10.0 seconds total elapsed foreground time.
  - Exponential backoff for transient failures (`timeout`, `network`, `429`, `503`).
- **Remote Dispatch**:
  - Sends `X-Operation-Key: <operationKey>` header via `MockSyncRemoteDataSource` (tagged `PROVISIONAL_DEVELOPMENT_FIXTURE_NOT_OFFICIAL_AIRMAN_DATA`).
- **Mid-Upload Session Switch**:
  - Captures `startGeneration = sessionManager.sessionGeneration`.
  - If `!sessionManager.isGenerationValid(startGeneration)`:
    - UI state notifications are dropped.
    - If server ACK was valid, commits acknowledgement to SQLite for the owning learner.
    - If network failed, resets record to `pending` with the exact same `operationKey` so it is recoverable.
- **Atomic Acknowledgement Persistence**:
  Executed in `database.transaction(...)`:
  1. Validate server acknowledgement signature and payload.
  2. Persist `serverAcknowledgement` receipt in `SubmissionOutbox`.
  3. Update `SubmissionOutbox.status = completed`.
  4. Update `QuizDrafts.draftStatus = acknowledged`.
  5. Commit together.

### 2.6 Lease Recovery
- Application startup & pre-sync check:
  - Finds any records with `status == in_flight` where `leaseExpiresAt < now`.
  - Recovers them to `pending` or `retry_scheduled` based on `attemptCount`.
  - Preserves `operationKey` and `encryptedPayload`.

### 2.7 Shared Token Refresh Coordination in `AuthInterceptor`
- Mutex/Completer pattern in `AuthInterceptor`:
  - When concurrent 401s occur, exactly one remote `refreshSession()` is in-flight.
  - All waiting requests await the same refresh completion.
  - Late 401s from expired session generations are ignored and cannot invalidate a new session.
  - Re-tries the original request at most once.

### 2.8 Presentation Layer: `SyncBloc`
- States:
  - `SyncInitial`
  - `SyncStaging`
  - `SyncInProgress(outboxId, attemptCount, timeElapsed)`
  - `SyncSuccess(acknowledgement, isOfflineQueued)`
  - `SyncTransientFailure(message, nextRetryIn, canRetry)`
  - `SyncBlocked(reason, lessonId, revisionId)`
  - `SyncAuthRequired`

---

## 3. Step-by-Step Implementation Sequence

1. **Foundations**: Create `UuidGenerator` and canonical AAD serialization.
2. **Schema v3**: Create `SubmissionOutboxTable`, update `QuizDraftsTable` with `draftStatus`, update `AppDatabase` migration to v3, run `build_runner`.
3. **Sync Domain & Data Layer**:
   - Entities: `SubmissionRecord`, `OutboxStatus`, `FailureCategory`, `SubmissionSnapshot`, `ServerAcknowledgement`.
   - Datasources: `SyncLocalDataSource` (atomic staging & lease queries), `MockSyncRemoteDataSource`.
   - Repositories: `SyncRepository`, `SyncRepositoryImpl`.
4. **Token Refresh Coordination**: Harden `AuthInterceptor` with single-flight mutex.
5. **Sync Engine**: Implement `SyncEngine` with bounded foreground budget (3 attempts / 10s ceiling).
6. **Presentation Layer**: Implement `SyncBloc`, UI status indicators, and manual retry hooks in `QuizPage`.
7. **Comprehensive Test Suite**:
   - Migration test (v2 &rarr; v3 data preservation).
   - Staging atomicity & draft preservation.
   - Outbox tenant isolation (Learner A vs Learner B).
   - Lease recovery after simulated crash.
   - Idempotent retries reusing exact `operationKey`.
   - Mid-flight session invalidation.
   - Canonical AAD verification & plaintext fallback rejection.
   - 409 stale content blocking without answer remapping.
   - Bounded foreground budget exhaustion.
8. **Final Quality Gate**: `dart format`, `flutter analyze`, `flutter test`, `flutter build apk --debug`.
