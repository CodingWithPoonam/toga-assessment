# PHASE 6.3 IMPLEMENTATION REPORT — PERSISTENT MOCK SERVER & IDEMPOTENCY VALIDATION

## 1. Executive Summary

This report documents the completion of **Phase 6.3 — Persistent Mock Server & Idempotency Validation** for the `toga_assessment` Flutter mobile application, aligning directly with the official AIRMAN Senior Flutter Lead candidate kit requirements.

Phase 6.3 resolves the critical gap identified in Phase 6.1 regarding **Scenario 04 (Lost-response recovery)**: previously, the mock server stored committed submission receipts only in an in-memory Dart `Map`, meaning that simulated or actual application process restarts wiped out the server's committed state, making true lost-response reconciliation across process restarts impossible to test deterministically without cheating.

With this implementation:
1. Committed server records are persisted independently of the client database using an injectable `IMockServerStore` disk-backed implementation (`FileMockServerStore`).
2. Server records persist across client database closure, client dependency injection reset (`GetIt.reset()`), and complete `SyncRemoteDataSource` disposal and reinitialization.
3. Server records are strictly partitioned by authenticated owner and operation key (`${owner}:${operationKey}`).
4. Request body canonical hashing detects mutated replays and throws HTTP 409 `IDEMPOTENCY_CONFLICT`.
5. Reconcile-before-stale logic ensures a committed attempt for an older revision reconciles with HTTP 200 even after the server's active revision has progressed, while uncommitted stale attempts are properly rejected.
6. A genuine restart test recreates both client and server datasources from real disk files, verifying zero loss of committed state.

---

## 2. Mock Server Persistence Architecture

### 2.1 Abstract Contract & Disk Store Implementation

In [lib/features/sync/data/datasources/sync_remote_datasource.dart](file:///c:/Users/z/.gemini/antigravity-ide/scratch/toga_assessment/lib/features/sync/data/datasources/sync_remote_datasource.dart):

```dart
abstract class IMockServerStore {
  Map<String, CommittedSubmission> loadCommittedSubmissions();
  void saveCommittedSubmissions(Map<String, CommittedSubmission> submissions);
  void clear();
}
```

Two concrete implementations are provided:
- **`FileMockServerStore`**: Persists committed submissions as deterministic JSON to an isolated file on disk with synchronous OS flush (`flush: true`). Survives client application restarts and datasource recreation.
- **`InMemoryMockServerStore`**: In-memory backing for fast, isolated unit tests.

### 2.2 Scoped Operation Keys and Canonical Body Matching

Server-side committed records are keyed deterministically by:
$$\text{scopedKey} = \text{learnerId} + ":" + \text{operationKey}$$

Every submission computes a canonical request-body string containing lexicographically sorted answer keys:
```dart
String _canonicalizeAnswers(Map<String, String> answers) {
  final sortedKeys = answers.keys.toList()..sort();
  final sortedMap = {for (final k in sortedKeys) k: answers[k]};
  return jsonEncode(sortedMap);
}
```

When a request arrives with an existing `scopedKey`:
- If the incoming canonical request body matches the recorded canonical body, the mock server returns **HTTP 200** with the original immutable `SyncSubmissionResponse` (`isIdempotentDuplicate = true`).
- If the incoming canonical request body differs, the server rejects the request with **HTTP 409 `IDEMPOTENCY_CONFLICT`** without altering the committed record or creating duplicate entries.

### 2.3 Reconcile-Before-Stale Logic

In `SyncRemoteDataSource.submitQuizAttempt`:
```dart
// 1. Evaluate idempotency BEFORE stale content checking
final scopedKey = '${snapshot.learnerId}:$operationKey';
if (_committedOperations.containsKey(scopedKey)) {
  final committed = _committedOperations[scopedKey]!;
  if (committed.canonicalRequestBody == canonicalBody) {
    return committed.response.copyWith(
      isIdempotentDuplicate: true,
      httpStatusCode: 200,
    );
  } else {
    throw const ConflictException(
      'IDEMPOTENCY_CONFLICT: Operation key already used with different payload',
    );
  }
}

// 2. Check current content revision only for NEW uncommitted attempts
final activeRevision = currentLessonRevisions[snapshot.lessonId] ?? snapshot.revisionId;
if (activeRevision != snapshot.revisionId) {
  throw const ConflictException(
    'STALE_CONTENT: Content revision superseded on server',
  );
}
```
Evaluating idempotency *before* revision freshness ensures that lost responses for older revisions reconcile with HTTP 200, while fresh submissions against stale content are rejected.

---

## 3. Test Suite & Verification Results

A dedicated test suite was created in [test/unit/features/sync/mock_server_persistence_test.dart](file:///c:/Users/z/.gemini/antigravity-ide/scratch/toga_assessment/test/unit/features/sync/mock_server_persistence_test.dart) containing 7 focused test cases.

### 3.1 Test Execution Matrix

| # | Test Name | Scenario / Requirement | Status | Assertions & Invariants |
|---|---|---|:---:|---|
| 1 | `1. Same-key same-body: 201 on first, 200 on second, identical ack, 1 record` | Idempotency Success | **PASSED** | First dispatch $\to$ 201 Created; second dispatch $\to$ 200 OK, `isIdempotentDuplicate: true`, identical `submissionId`, exactly 1 record on server. |
| 2 | `2. Same-key changed-body: returns 409 IDEMPOTENCY_CONFLICT without overwriting original` | Conflict Detection | **PASSED** | Mutated answers under same key throws `ConflictException` with code `IDEMPOTENCY_CONFLICT`. Original committed submission remains unchanged. |
| 3 | `3. Cross-owner isolation: Learner A and B using identical operation key remain isolated` | Tenant Isolation | **PASSED** | Learner A and Learner B using identical `opKey` commit 2 distinct submissions; Learner B cannot access Learner A's acknowledgement. |
| 4 | `4. Reconcile-before-stale: Committed rev 1 reconciles after server bumps to rev 2; new rev 1 rejected` | Reconcile Order | **PASSED** | Committed rev 1 returns 200 OK after server bumps to rev 2. Fresh rev 1 attempt with new key throws `STALE_CONTENT`. |
| 5 | `5. Server recreation: Destroying and recreating SyncRemoteDataSource recovers disk-persisted state` | Server Disk Recovery | **PASSED** | First `SyncRemoteDataSource` commits to file; instance is set to `null`; second new instance constructed from same file recovers state and returns 200 replay. |
| 6 | `6. Scenario 04 E2E: Client process crash and server datasource recreation reconciles lost response` | **Scenario 04 E2E** | **PASSED** | Real `AppDatabase(NativeDatabase(clientDbFile))` and `SyncRemoteDataSource` simulate crash: DB closed, GetIt reset, new instances created from files, sync retried, outbox reconciles to `completed`. |
| 7 | `7. Storage resilience: Handles corrupted JSON store gracefully or throws explicit error` | Storage Resilience | **PASSED** | Corrupted non-JSON file gracefully defaults to empty store in resilient mode, or raises `ServerStoreException` in strict mode. |

### 3.2 Evidence of Genuine Process Restart (Scenario 04)

In Test 6:
```dart
// Step 4: Server commits submission, but response drops
serverDataSource.simulateCommitWithLostResponse = true;
final firstResult = await syncEngine.synchronize(learnerId: 'learner_a');
expect(firstResult.outcome, equals(SyncOutcomeStatus.transientFailure));

// Step 5: SIMULATE HARD PROCESS TERMINATION
// Close client DB, reset GetIt, drop server datasource
await database.close();
await getIt.reset();

// Step 6: RELAUNCH APP & RECREATE SERVER DATASOURCE
final restartedDb = AppDatabase(NativeDatabase(clientDbFile));
final restartedServerSource = SyncRemoteDataSource(
  simulatedLatency: Duration.zero,
  persistentStorageFile: serverStoreFile,
);
...
// Step 7: Retry sync after relaunch: server reconciles and returns original committed receipt
final retryResult = await restartedSyncEngine.synchronize(learnerId: 'learner_a');
expect(retryResult.outcome, equals(SyncOutcomeStatus.success));
expect(retryResult.operationKey, equals(initialOperationKey));

// Verify outbox completed in client DB
final outboxRecord = await restartedSyncRepo.getOutboxByOperationKey(initialOperationKey);
expect(outboxRecord!.status, equals(OutboxStatus.completed));
expect(outboxRecord.serverAcknowledgement, contains('accepted'));
```

---

## 4. Full Quality Suite Execution

### 4.1 Static Analysis
Command:
```powershell
flutter analyze
```
Output:
```
Analyzing toga_assessment...
No issues found! (ran in 2.1s)
```

### 4.2 Automated Test Suite
Command:
```powershell
flutter test
```
Output:
```
00:17 +92: All tests passed!
```
Total tests passed: **92 / 92** (100% pass rate).

---

## 5. Files Changed & Created

1. **[lib/features/sync/data/datasources/sync_remote_datasource.dart](file:///c:/Users/z/.gemini/antigravity-ide/scratch/toga_assessment/lib/features/sync/data/datasources/sync_remote_datasource.dart)**:
   - Added `IMockServerStore`, `InMemoryMockServerStore`, `FileMockServerStore`, and `ServerStoreException`.
   - Added `CommittedSubmission` entity with canonical payload serialization.
   - Implemented canonical request body hashing and `IDEMPOTENCY_CONFLICT` checking.
   - Implemented reconcile-before-stale logic.
   - Supported disk persistence via `File? persistentStorageFile`.
2. **[test/unit/features/sync/mock_server_persistence_test.dart](file:///c:/Users/z/.gemini/antigravity-ide/scratch/toga_assessment/test/unit/features/sync/mock_server_persistence_test.dart)**:
   - Created comprehensive 7-test suite verifying server store disk persistence, idempotency conflict, cross-owner isolation, reconcile-before-stale, and end-to-end crash recovery.

---

## 6. Outstanding Gaps & Next Steps (Phase 6.4)

Phase 6.3 is fully verified and complete. The remaining candidate kit requirements for Phase 6.4 are:
1. **Legacy Migration Service (Scenario 11)**:
   - Ingest `data/legacy_private_v1.json` from SharedPreferences into encrypted Drift SQLite after reauthentication.
   - Enforce learner owner matching and re-encryption.
   - Test corrupted legacy JSON and unavailable encryption key paths.
2. **Large Font Accessibility & Overflow Verification (Scenario 12)**:
   - Widget test with 200% text scale factor on small screen dimensions ($320 \times 480$).
   - Verify zero RenderFlex overflow errors and touch targets $\ge 48 \times 48$ dp.
3. **Documentation Alignment (Phase 6.5)**:
   - Realignment of `docs/ENGINEERING_REVIEW.md` line numbers against official `review/legacy_*.dart`.
   - Integration of `data/incident_observations.csv` telemetry metrics into `docs/DELIVERY_PLAN.md` and `docs/LEADERSHIP.md`.
