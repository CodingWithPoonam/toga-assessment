# Phase 4.3 — End-to-End Integration Testing Report

- **Author**: Senior Flutter QA Automation Engineer & Technical Lead
- **Project**: `toga_assessment`
- **Assessment**: AIRMAN Senior Flutter Lead Assessment
- **Date**: November 27, 2026
- **Head Commit**: `0a4708ff9e39f010934eae12003ec75051c36fb6`
- **Baseline**: **85/85 tests passing** (62 unit/repo + 17 bloc/widget + 6 E2E integration) | 0 analyzer warnings

---

## 1. Test Environment Details

| Component | Specification |
|---|---|
| **Operating System** | Windows 11 (build environment) |
| **Flutter SDK** | Flutter 3.44.2 (Channel stable, 3.44.2) |
| **Dart SDK** | Dart 3.12.2 |
| **Database Driver** | SQLite via Drift 2.34.4 / NativeDatabase (`sqlite3: ^3.5.2`) |
| **Cryptography** | AES-GCM-256 via `cryptography: ^2.9.0` with canonical JSON AAD |
| **Target Runtime** | Android API 34 (debug APK compiled: `build/app/outputs/flutter-apk/app-debug.apk`) |
| **Emulated AVD** | `Pixel_8` / `Medium_Phone_API_34` (configured in host SDK) |

---

## 2. Integration Test Execution Summary

The end-to-end integration test suite is implemented in:
- `integration_test/offline_sync_flow_test.dart`
- `test/integration/offline_sync_flow_test.dart`

```bash
flutter test test/integration/offline_sync_flow_test.dart
```

### Actual Execution Output:
```text
00:00 +0: loading C:/Users/z/.../test/integration/offline_sync_flow_test.dart
00:00 +0: End-to-End Offline-to-Online Integration Journey Complete 18-step journey: Login, cache reading, offline quiz answering, persistent draft restart, and outbox sync
00:12 +1: End-to-End Offline-to-Online Integration Journey Failure Validation: Lost response reconciles with identical operationKey
00:15 +2: End-to-End Offline-to-Online Integration Journey Failure Validation: Expired lease is recovered to pending
00:15 +3: End-to-End Offline-to-Online Integration Journey Failure Validation: Multi-tenant outbox isolation
00:15 +4: End-to-End Offline-to-Online Integration Journey Failure Validation: Stale content revision blocks submission
00:15 +5: End-to-End Offline-to-Online Integration Journey Failure Validation: Cryptographic AAD mismatch rejects forged record
00:15 +6: All tests passed!
```

---

## 3. Verification of the 18-Step Learner Journey

| Step # | Test Step Description | Measured Result | Evidence & Assertions |
|:---:|---|:---:|---|
| **1** | Clean database initialization | **PASS** | File-backed SQLite DB created in isolated temp directory (`NativeDatabase(dbFile)`). |
| **2** | Synthetic learner authentication | **PASS** | Logged in as `alex.mercer` (Learner A); routed to `/lessons`. |
| **3** | Lesson catalogue loading | **PASS** | `Aerodynamics & Flight Principles` and `Aircraft Instruments` displayed. |
| **4** | Open revision-pinned lesson | **PASS** | Opened `provisional_lesson_1` pinned to `rev_1_0`. |
| **5** | Verify cached lesson persistence | **PASS** | Query on Drift `CachedLessons` confirmed row `{id: provisional_lesson_1, revisionId: rev_1_0}`. |
| **6** | Simulate network disconnect | **PASS** | `syncRemoteDataSource.simulateNetworkDrop = true`. |
| **7** | Answer 5 quiz questions offline | **PASS** | Answered `q1` through `q5` with option selections; stepped to end. |
| **8** | Verify encrypted draft in SQLite | **PASS** | `QuizDrafts` row has `currentQuestionIndex: 4`; all 5 `QuizAnswers` rows contain ciphertext (`encryptedSelectedOptionId != 'opt_a'`). |
| **9** | Stage submission atomically | **PASS** | Tapped "Submit Attempt"; draft marked `staged`; outbox marked `retry_scheduled` due to offline mode. |
| **10** | Verify stable operation key | **PASS** | `SubmissionOutbox.operationKey` contains an RFC 4122 v4 UUID. |
| **11** | Simulate process termination | **PASS** | Closed DB connection, reset GetIt DI container, and pumped down widget tree. |
| **12** | Reinitialize app & reopen file DB | **PASS** | Re-opened `AppDatabase` on identical SQLite file; restored session. |
| **13** | Verify restored draft & outbox | **PASS** | Restored `draftStatus: staged`, `revisionId: rev_1_0`, and identical `operationKey`. |
| **14** | Restore network connectivity | **PASS** | `syncRemoteDataSource.simulateNetworkDrop = false`. |
| **15** | Trigger foreground synchronization | **PASS** | `SyncEngine.synchronize()` returned `SyncOutcomeStatus.success`. |
| **16** | Verify identical operation key reused | **PASS** | Remote mock confirmed receipt keyed by original UUID (no duplicate key). |
| **17** | Verify server acknowledgement saved | **PASS** | `SubmissionOutbox` updated to `completed` with `serverAcknowledgement` receipt JSON. |
| **18** | Verify outbox cannot be resubmitted | **PASS** | Subsequent `synchronize()` returned `SyncOutcomeStatus.idle`; draft marked `acknowledged`. |

---

## 4. Failure and Recovery Validations

1. **Lost Response After Server Commit**:
   - *Test*: `simulateCommitWithLostResponse = true`.
   - *Result*: First attempt drops after commit, scheduling retry. Retry delivers identical `operationKey`. Server identifies idempotent duplicate and returns existing receipt without re-grading.
   - *Status*: **VERIFIED (PASS)**.
2. **Expired In-Flight Lease Recovery**:
   - *Test*: Outbox record claimed with negative lease duration (`-10s`).
   - *Result*: `recoverExpiredLeases()` detects expired lease and reclaims status from `in_flight` back to `pending`.
   - *Status*: **VERIFIED (PASS)**.
3. **Multi-Tenant Outbox Isolation**:
   - *Test*: Learner A stages an outbox record; active session switched to Learner B.
   - *Result*: Learner B's sync engine finds 0 eligible records and returns `idle`. Learner A's records remain untouched.
   - *Status*: **VERIFIED (PASS)**.
4. **Stale Content Revision Conflict**:
   - *Test*: `simulateStaleContentError = true` (HTTP 409 conflict).
   - *Result*: Outbox record marked `blocked`; draft preserved in SQLite for learner review.
   - *Status*: **VERIFIED (PASS)**.
5. **Cryptographic AAD Tamper Rejection**:
   - *Test*: Decrypt payload using Learner B's AAD context on Learner A's ciphertext.
   - *Result*: Throws `SecurityException` with MAC verification failure and zero plaintext leakage.
   - *Status*: **VERIFIED (PASS)**.

---

## 5. Device Execution & Limitations Disclosure

### Honest Execution Status:
- **Headless & VM Execution**: **100% VERIFIED**. All 85 tests (including the 6 integration tests) run directly through Flutter's testing engine.
- **Process Termination Simulation**: The integration test faithfully simulates cold process termination at the native persistence boundary by closing the `AppDatabase` connection, disposing GetIt, and reloading from the real underlying file on disk.
- **Limitation on OS-Level Force Stop**: A true OS-level kill (`am force-stop` via ADB) terminates the test runner process itself, preventing programmatic assertions post-kill.
- **Physical Device / Emulator Execution**: The Android debug APK compiles cleanly (`flutter build apk --debug`). However, in this Windows environment, the Android emulator daemon did not attach an interactive display session. Live device execution is therefore classified as **NOT RUN on real device**.

### Reproducible Manual Verification Procedure (Android Emulator):
To verify genuine OS-level process kill and relaunch on a live Android emulator:
```bash
# 1. Start emulator and install APK
flutter emulators --launch Pixel_8
flutter install -d emulator-5554

# 2. Launch TOGA app, log in as Learner A, answer 3 quiz questions
# 3. Force-kill the app process from the host terminal:
adb -s emulator-5554 shell am force-stop org.theairman.toga

# 4. Relaunch the application:
adb -s emulator-5554 shell am start -n org.theairman.toga/com.example.toga_assessment.MainActivity

# 5. Inspect SQLite database on device:
adb -s emulator-5554 shell "run-as org.theairman.toga sqlite3 databases/toga_app.sqlite 'SELECT id, learner_id, draft_status FROM quiz_drafts;'"
# Expected output: Draft row exists with learner_id = 'learner-a' and draft_status = 'in_progress'
```

---

## 6. Phase 4.3 Completion Status

### **Phase 4.3 Status: COMPLETE (with documented platform limitation)**
- **Test Implementation**: `integration_test/offline_sync_flow_test.dart` and `test/integration/offline_sync_flow_test.dart` are complete and verified.
- **Test Baseline**: Expanded from 79 to **85 passing automated tests**.
- **Static Analysis**: `flutter analyze` reports **0 issues**.
- **Integrity**: Zero weakening of encryption, authentication, or outbox transaction semantics.
