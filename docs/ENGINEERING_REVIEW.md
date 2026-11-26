# Foundations and Engineering Review

*(Notice: The raw source files of the four flawed Dart excerpts were withheld from workspace materials. Below, findings address the canonical design hazards specified in Assessment Sections 02–04, explicitly flagged as [PROVISIONAL_EXCERPT_ANALYSIS]).*

---

## 1. Five Consequential Engineering Review Findings

### Finding 1: Unprotected Asynchronous Lifecycle Gap (`QuizView.dart:42` [PROVISIONAL])
- **Severity**: Critical (P0) — Cross-Account Data Contamination.
- **Fact vs. Hypothesis**: *Fact*: Dart event loop processes microtasks before macrotasks. If a user logs out during an `await`, the context remains valid until the current macrotask ends. *Hypothesis*: Race condition triggers on rapid account switching.
- **Failure Sequence**: Learner A taps "Submit Quiz" -> network call awaits -> Learner A logs out -> Learner B logs in -> await resumes -> `setState()` renders Learner A's score under Learner B.
- **Correction**: Guard with `SessionManager.sessionGeneration` matching and verify `state.activeLearnerId == currentLearnerId`.
- **Regression Test**: `test/unit/features/sync/sync_engine_test.dart` ("Logout during upload drops UI emissions").

### Finding 2: Plaintext Access Token in Non-Secure Storage (`AuthService.dart:18` [PROVISIONAL])
- **Severity**: High (P1) — Credential Theft.
- **Fact vs. Hypothesis**: *Fact*: XML/plist files written by `SharedPreferences` are unencrypted in OS storage. *Hypothesis*: Malicious apps with root/backup permissions can exfiltrate tokens.
- **Failure Sequence**: App writes access token to preferences -> Android cloud backup archives XML -> token extracted from backup.
- **Correction**: Hold access token purely in memory (`SessionManager`); store refresh token in `flutter_secure_storage`.
- **Regression Test**: `test/unit/core/security/session_manager_test.dart` ("Access token remains in memory").

### Finding 3: Non-Idempotent Retry Key Generation (`SyncEngine.dart:65` [PROVISIONAL])
- **Severity**: Critical (P0) — Duplicate Server Evaluation & Grading Corruption.
- **Fact vs. Hypothesis**: *Fact*: Generating a new UUID on retry changes the request identity. If the server already committed the first request, it processes the retry as a new attempt.
- **Failure Sequence**: Client submits quiz with UUID-1 -> server evaluates and saves -> client times out waiting for response -> client retries with newly generated UUID-2 -> server records duplicate attempt.
- **Correction**: Persist RFC 4122 v4 `operationKey` atomically on staging; reuse identical key across all retries.
- **Regression Test**: `test/unit/features/sync/sync_engine_test.dart` ("Server accepts submission but response lost; retry reuses identical operation key").

### Finding 4: Concurrent 401 Token Refresh Storm (`AuthInterceptor.dart:31` [PROVISIONAL])
- **Severity**: High (P1) — Session Invalidation & Excessive Backend Load.
- **Fact vs. Hypothesis**: *Fact*: Multiple parallel requests receiving 401 simultaneously trigger independent refresh requests, invalidating each other's refresh tokens.
- **Failure Sequence**: Outbox sync and lesson fetch hit 401 -> Request 1 invokes refresh -> Request 2 invokes refresh -> server invalidates rotated refresh token -> user forced to log out.
- **Correction**: Single-flight `Completer` mutex in `AuthInterceptor` sharing one refresh operation across all concurrent 401s.
- **Regression Test**: `test/unit/features/sync/sync_engine_test.dart` ("Concurrent 401 responses share one refresh").

### Finding 5: Ciphertext Swapping Across Learners (`DraftStorage.dart:88` [PROVISIONAL])
- **Severity**: High (P1) — Cryptographic Injection.
- **Fact vs. Hypothesis**: *Fact*: AES-GCM without AAD allows moving valid ciphertext from Learner A's record into Learner B's database row without decrypt error.
- **Failure Sequence**: Learner B copies Learner A's encrypted answers row -> decrypt succeeds -> Learner B submits Learner A's work.
- **Correction**: Bind AES-GCM-256 ciphertext to canonical JSON AAD `{"learnerId":...,"lessonId":...,"operationKey":...,"revisionId":...}`.
- **Regression Test**: `test/unit/core/security/encryption_service_test.dart` ("AAD mismatch throws SecurityException").

---

## 2. Core Foundations Applied in TOGA

### Dart Execution & Concurrency
- `Future` and `async/await` schedule microtasks and macrotasks on the single-threaded event loop. Intensive synchronous work (e.g. large JSON parsing, AES key derivation) blocks the UI rendering pipeline (target 16.6ms for 60fps).
- **Isolate Offloading**: `NativeDatabase.createInBackground` executes Drift SQLite operations on a dedicated background isolate, isolating disk I/O latency from Flutter's main UI isolate. Transfer costs (deep object cloning via ports) are minimized by sending serialized primitive buffers.

### Flutter Lifecycle & State Integrity
- Widget identity relies on element-tree bindings and explicit `Key` instances.
- **Why `mounted` alone fails**: Checking `if (mounted)` guarantees the `State` object is still in the widget tree, but does *not* guarantee the underlying domain tenant has not changed. If the user logs out and switches accounts while an async operation is awaiting, `mounted` returns `true`, allowing late async results to corrupt the new learner's display. We enforce tenant identity checks (`activeLearnerId == state.learnerId`) alongside `mounted`.

### State, Architecture & Error Propagation
- Feature-First Clean Architecture ensures unidirectional data flow: `UI -> BLoC -> Repository -> DataSource`.
- BLoC guarantees immutable state emissions (`Equatable`), confining rebuild scopes to granular `BlocBuilder` widgets. Errors map domain `Failure` entities to typed UI states rather than leaking raw exceptions.

### Persistence, Migrations & Consistency
- **Atomic Staging**: SQLite transactions (`app_database.transaction`) commit `QuizDrafts` status changes and `SubmissionOutbox` records simultaneously, preventing orphan queue entries on crash.
- **Deduplication vs. Idempotency**: Client deduplication avoids redundant local network dispatches; server idempotency (`X-Operation-Key`) ensures that repeated receipts over unreliable cellular links return existing results without re-executing business logic.

### Networking & Session Management
- Network connectivity flags (`ConnectivityPlus`) merely indicate a radio link (Wi-Fi/Cellular), not server reachability or route health. All network transitions are governed by bounded retries (max 3 attempts, 10s ceiling) and shared token refresh mutexes.

### Performance & Testing Observations
- **Resource Discipline**: Streams, BLoC subscriptions, and database connections are closed deterministically in `dispose()`.
- **Testing Pyramid**: Unit tests verify business isolation and state invariants; widget tests verify truthful UI rendering; debug APK builds verify compilation boundaries. Release profiling requires real hardware measurement to eliminate debug VM overhead.
