# Foundations & Engineering Review

This engineering review evaluates the four static review excerpts from the official candidate kit: `review/legacy_auth.dart`, `review/legacy_cache.dart`, `review/legacy_study_page.dart`, and `review/legacy_sync.dart`. Every finding specifies exact lines, original behavior, technical risk, concrete reproduction, corrected implementation, and regression test evidence.

---

## 1. Consequential Engineering Review Findings

### Finding 1: Permissive TLS Verification & Plaintext Logging (`review/legacy_auth.dart:11-17`)
- **Location**: `review/legacy_auth.dart`, Lines 11–13 (`badCertificateCallback = (cert, host, port) => true;`) and Line 17 (`print('request: ${options.headers} ${options.data}');`).
- **Original Behavior**: Bypasses X.509 certificate validation and prints raw headers and payloads directly to stdout.
- **Technical Risk**: **Critical (P0)**. Disabling TLS validation permits machine-in-the-middle (MITM) attacks on public Wi-Fi. Printing headers exposes bearer tokens and student quiz answers to system logcat/syslog.
- **Reproduction Steps**:
  1. Route traffic through an HTTP proxy using an untrusted self-signed certificate.
  2. Issue a request with `makeClient()`; connection succeeds without warning.
  3. Inspect system console logs to read plaintext `Authorization` bearer tokens.
- **Corrected Implementation**: In [lib/core/network/dio_client.dart](file:///c:/Users/z/.gemini/antigravity-ide/scratch/toga_assessment/lib/core/network/dio_client.dart), strict platform certificate validation is enforced with zero permissive callbacks. Console token logging is eliminated.
- **Regression Test**: Verified in `test/unit/core/network/dio_client_test.dart` ("Secure transport rejects invalid certificates").

### Finding 2: Unbounded Recursive 401 Refresh Loop (`review/legacy_auth.dart:20-30`)
- **Location**: `review/legacy_auth.dart`, Lines 20–30 (`onError` handler).
- **Original Behavior**: On receiving HTTP 401, invokes `dio.post('/auth/refresh')` on the *same* `dio` client without interceptor guards, loop counters, or token rotation.
- **Technical Risk**: **Critical (P0)**. If the refresh token is revoked or expired, `/auth/refresh` returns 401. This re-triggers `onError` recursively, causing memory exhaustion, client crashes, and backend denial-of-service.
- **Reproduction Steps**:
  1. Configure an expired `refresh_token` in storage.
  2. Dispatch an authenticated request returning 401.
  3. Observe infinite recursive calls to `/auth/refresh` until stack overflow.
- **Corrected Implementation**: In [lib/core/network/auth_interceptor.dart](file:///c:/Users/z/.gemini/antigravity-ide/scratch/toga_assessment/lib/core/network/auth_interceptor.dart), token refresh uses an isolated `Dio` instance without interceptors. A single-flight `Completer` mutex coalesces concurrent 401s. Refresh failure halts recursion, evicts session state, and redirects to login.
- **Regression Test**: Verified in `test/unit/features/auth/auth_repository_test.dart` ("Single-flight refresh mutex coalesces concurrent 401s; invalid refresh stops recursion").

### Finding 3: Plaintext Storage & Incomplete Logout (`review/legacy_cache.dart:4-10`)
- **Location**: `review/legacy_cache.dart`, Lines 4–6 (`saveDraft`) and Lines 7–10 (`logout`).
- **Original Behavior**: Saves unencrypted JSON drafts to `SharedPreferences` (`draft_$lessonId`). Logout removes only `access_token`, leaving `refresh_token` and drafts on disk.
- **Technical Risk**: **High (P1)**. Unencrypted XML preferences allow credential extraction via backups or rooted devices. On shared devices, Learner B inherits Learner A's residual refresh token and private drafts.
- **Reproduction Steps**:
  1. Learner A saves a draft and taps logout.
  2. Inspect sandbox preferences: `refresh_token` and `draft_<lessonId>` remain.
  3. Learner B logs in: application accesses Learner A's residual draft.
- **Corrected Implementation**: In [lib/core/security/session_manager.dart](file:///c:/Users/z/.gemini/antigravity-ide/scratch/toga_assessment/lib/core/security/session_manager.dart) and [lib/features/quiz/data/datasources/quiz_local_datasource.dart](file:///c:/Users/z/.gemini/antigravity-ide/scratch/toga_assessment/lib/features/quiz/data/datasources/quiz_local_datasource.dart), access tokens remain in memory; refresh tokens reside in hardware secure storage; drafts are encrypted via AES-GCM-256 with owner AAD. Logout wipes all tokens, active drafts, and session keys.
- **Regression Test**: Verified in `test/unit/features/auth/auth_repository_test.dart` ("Logout purges session and tokens cleanly") and `test/integration/offline_sync_flow_test.dart` ("Multi-tenant outbox isolation").

### Finding 4: Unmanaged Subscription, Lifecycle Leaks & Build Side-Effects (`review/legacy_study_page.dart:16-25`)
- **Location**: `review/legacy_study_page.dart`, Line 16 (`widget.repo.events.listen`), Lines 19–22 (`load`), and Line 25 (`widget.repo.saveProgress` inside `build`).
- **Original Behavior**: `initState` opens a stream subscription without cancelling it on `dispose`. `load()` calls `setState()` asynchronously without `mounted` checks. `build()` triggers storage writes on every layout frame.
- **Technical Risk**: **High (P1)**. Firing events on disposed widgets causes memory leaks and `setState() called after dispose`. Saving progress in `build()` creates infinite re-render loops. Delayed responses overwrite newer lessons when quickly switching routes.
- **Reproduction Steps**:
  1. Open `StudyPage` and pop back before `load()` finishes.
  2. Observe `FlutterError: setState() called after dispose()`.
  3. Trigger layout pass; observe repeated unprompted `saveProgress` invocations.
- **Corrected Implementation**: State management migrated to BLoC (`LessonBloc`, `QuizBloc`) with strict unidirectional data flow. Generation tracking (`_activeDetailGeneration`) drops stale responses; subscriptions cancel on bloc close; widget rendering is pure.
- **Regression Test**: Verified in [test/widget/accessibility_and_layout_test.dart](file:///c:/Users/z/.gemini/antigravity-ide/scratch/toga_assessment/test/widget/accessibility_and_layout_test.dart) ("Disposed bloc safety", "Stream subscription cleanup", "Delayed lesson fetch cancellation").

### Finding 5: Preemptive Queue Erasure & Non-Idempotent Retries (`review/legacy_sync.dart:4-14`)
- **Location**: `review/legacy_sync.dart`, Line 6 (`await store.remove('pending')`) and Lines 9–14 (`Idempotency-Key: uuid.v4()`).
- **Original Behavior**: Erases pending submissions from disk *before* network delivery. On retry inside the catch block, generates a fresh UUID idempotency key.
- **Technical Risk**: **Critical (P0)**. Network timeouts or process kills destroy unacknowledged student submissions permanently. Generating new UUIDs on retry causes the server to process duplicates, corrupting grading records.
- **Reproduction Steps**:
  1. Enqueue submission and trigger `drain()`.
  2. Kill app process while network POST awaits.
  3. Reopen app: pending queue is empty; student submission is permanently lost.
- **Corrected Implementation**: In [lib/features/sync/data/datasources/sync_local_datasource.dart](file:///c:/Users/z/.gemini/antigravity-ide/scratch/toga_assessment/lib/features/sync/data/datasources/sync_local_datasource.dart), submissions use durable atomic statuses (`pending` $\to$ `in_flight` $\to$ `completed`). The RFC 4122 v4 UUID `operationKey` is persisted at staging and reused across all retries. Outbox rows are removed only after committed server acknowledgement.
- **Regression Test**: Verified in `test/unit/features/sync/mock_server_persistence_test.dart` ("Scenario 04 Lost response reconciles with identical operation key").

---

## 2. Core Architectural Foundations

1. **Concurrency**: Cryptography (AES-GCM-256) and SQLite I/O run off the UI thread using background isolates (`NativeDatabase.createInBackground`).
2. **Lifecycle Safety**: Tenant identity checks and monotonic generational counters prevent delayed microtasks from mutating subsequent user sessions.
3. **Data Integrity**: Drift SQLite transactions guarantee ACID boundaries for submissions and migrations. Server idempotency ensures reliable replay without duplicate grading.
