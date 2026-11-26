# AI Collaboration & Engineering Accountability

- **Candidate Role**: Senior Flutter Technical Lead
- **Project**: `toga_assessment`
- **Assessment**: AIRMAN Senior Flutter Lead Assessment
- **Date**: November 2026

---

## 1. AI Tools and Models Used
Development and architectural documentation for this project were conducted using:
- **Agentic Platform**: Antigravity Engineering Environment
- **Underlying Models**: Google DeepMind Gemini 3.8 Flash (Medium) and Gemini 3.8 Pro
- **Execution Mode**: Phased autonomous tool execution with human-in-the-loop architectural gating, code inspection, and test verification at every phase boundary.

---

## 2. Tasks Receiving AI Assistance
- **Phase 1 (Foundation)**: Directory scaffolding for Feature-First Clean Architecture, initial `injection.dart` registrations, `DioClient` timeout configuration, and Drift SQLite initialization.
- **Phase 2 (Authentication)**: `SessionManager` in-memory token scoping, `AuthInterceptor` single-flight refresh completer, and `GoRouter` authentication redirect guards.
- **Phase 3A (Offline Progress & Drafts)**: Drift schema version 2 (`CachedLessons`, `QuizDrafts`, `QuizAnswers`), AES-GCM-256 authenticated encryption service, and BLoC state machines.
- **Phase 3B (Outbox & Sync Engine)**: Schema version 3 migration (`SubmissionOutbox`), RFC 4122 v4 UUID `operationKey` generator, atomic SQLite staging transactions, and bounded foreground sync engine with exponential backoff.
- **Phase 4 (Review & Documentation)**: Automated repository inspection, `PHASE_4_GAP_ANALYSIS.md` gap matrix, `DELIVERY_PLAN.md`, `LEADERSHIP.md`, and STRIDE threat modeling in `SECURITY.md`.

---

## 3. Two Representative Prompts

### Prompt 1: Phase 3B Atomic Submission Staging
> *"Implement atomic submission staging in `SyncLocalDataSource`. In a single SQLite transaction, freeze the current `QuizDraft` by setting its `draftStatus` to `staged`, generate an RFC 4122 v4 UUID `operationKey`, encrypt the submission snapshot using AES-GCM-256 bound to canonical JSON AAD, and insert a new record into `SubmissionOutbox` with status `pending`. Add rollback verification tests."*

### Prompt 2: Phase 3A Review Correction (Revision-Aware Caching & AAD)
> *"Review the Drift schema for `CachedLessons` and `QuizRepository`. Update `CachedLessons` to use composite primary key `{id, revisionId}` and expose `getLessonByRevision`. Update `AesGcmEncryptionService` to bind ciphertext to a deterministic lexicographically sorted JSON string `{"learnerId":...,"lessonId":...,"operationKey":...,"revisionId":...}` so ciphertext cannot be swapped between learners or records."*

---

## 4. AI Suggestion Independently Verified, Corrected & Rejected

### The Flawed Suggestion: Timestamp-Derived Idempotency Key
During initial Phase 3B planning, the AI model proposed generating the idempotency `operationKey` deterministically from the draft update timestamp and composite string:
```dart
// Rejected AI proposal:
final operationKey = '${learnerId}_${lessonId}_${draft.updatedAt.millisecondsSinceEpoch}';
```

### Technical Critique & Rejection:
1. **Clock Skew & Collisions**: If a user updates two answers within the same millisecond or if the system clock steps backward (NTP sync), collisions occur.
2. **Ambiguous Draft Identity**: If a learner modifies a draft after a failed send, timestamp derivation mutates the idempotency key, creating a second logical submission on the server instead of reconciling the original attempt.

### Lead Correction Implemented:
We rejected this suggestion and enforced generating a cryptographically secure **RFC 4122 v4 UUID** (`UuidGenerator`) exactly once during staging, committing it atomically to `SubmissionOutbox.operationKey` in SQLite, and reusing that identical immutable key across all network retries.

---

## 5. Testing & Verification Methodology
Every piece of AI-assisted code was subjected to rigorous deterministic testing:
1. **Unit & BLoC Tests**: Automated tests (`bloc_test`, `mocktail`) verified state transitions, error mappings, and cancellation flows.
2. **ACID Transaction Rollback Tests**: In-memory Drift test instances verified that database failures during staging rollback all table mutations without orphan records.
3. **Cryptographic Tamper Tests**: Explicitly mutated ciphertext bytes and modified AAD parameters to ensure `AesGcmEncryptionService` throws `SecurityException` without plaintext fallback.
4. **Static Analysis & Compilation**: Verified with `flutter analyze --fatal-infos` (0 issues) and `flutter build apk --debug` (clean native compilation).

---

## 6. Privacy & Intellectual Property Affirmation
- **Zero Confidential Leakage**: No private AIRMAN source code, proprietary algorithms, production API keys, or live infrastructure details were uploaded or transmitted.
- **Synthetic Data Exclusively**: All test accounts (`learner-a`, `learner-b`) and fixtures are synthetic, clearly isolated behind interfaces, and flagged `PROVISIONAL_DEVELOPMENT_FIXTURE_NOT_OFFICIAL_AIRMAN_DATA`.
- **Engineering Accountability**: The human candidate retains 100% intellectual ownership, design responsibility, and accountability for all code, architectural trade-offs, and claims in this repository.
