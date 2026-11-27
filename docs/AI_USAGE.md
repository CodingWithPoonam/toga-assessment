# AI Collaboration & Engineering Accountability

- **Candidate Role**: Senior Flutter Technical Lead
- **Project**: `toga_assessment`
- **Assessment**: AIRMAN Senior Flutter Lead Candidate Assessment
- **Status Baseline**: 118/118 tests passing | 0 analyzer issues | Android debug APK verified

---

## 1. AI Tools and Exact Model Names
All AI-assisted architectural drafting, code generation, and test creation in this repository were conducted within:
- **Platform**: Antigravity Engineering Environment
- **Underlying Models**: **Google DeepMind Gemini 3.8 Flash** and **Google DeepMind Gemini 3.8 Pro**
- **Mode**: Phased agentic tool execution with continuous human-in-the-loop review, code inspection, and test verification at every phase boundary.

---

## 2. Areas Where AI Assistance Was Used
1. **Foundation & Architecture**: Project structure scaffolding for Feature-First Clean Architecture, initial GetIt service registration, Dio timeout configurations, and Drift SQLite setup.
2. **Session & Security**: `SessionManager` in-memory token scoping, `AuthInterceptor` single-flight refresh mutex, and AES-GCM-256 authenticated encryption service.
3. **Offline Persistence & Drift Migrations**: Drift schema evolution across versions 1, 2, and 3 (`CachedLessons`, `QuizDrafts`, `QuizAnswers`, `SubmissionOutbox`), composite primary key caching, and transaction boundaries.
4. **Outbox & Sync Engine**: RFC 4122 v4 UUID `operationKey` generator, atomic SQLite staging transactions, and bounded foreground sync engine with exponential backoff and lease recovery.
5. **Persistent Mock Server & Idempotency**: Injectable persistent mock storage verifying Scenario 04 replay, 409 `IDEMPOTENCY_CONFLICT` on body changes, and cross-learner isolation.
6. **Legacy Migration & Accessibility**: `LegacyMigrationService` importing `data/legacy_private_v1.json` with reauthentication and owner validation; responsive `Wrap` layouts for 200% font scaling on $320\text{px}$ screens; screen reader semantics; lifecycle generation guards.

---

## 3. Two Representative Prompts Actually Used

### Prompt 1: Phase 3B Atomic Submission Staging
> *"Implement atomic submission staging in `SyncLocalDataSource`. In a single SQLite transaction, freeze the current `QuizDraft` by setting its `draftStatus` to `staged`, generate an RFC 4122 v4 UUID `operationKey`, encrypt the submission snapshot using AES-GCM-256 bound to canonical JSON AAD, and insert a new record into `SubmissionOutbox` with status `pending`. Add rollback verification tests."*

### Prompt 2: Phase 6.4 Legacy Migration & Recovery Validation
> *"Implement `LegacyMigrationService` for the official `data/legacy_private_v1.json` fixture. Require reauthentication confirming the authenticated learner matches the draft owner. Validate lesson ID, revision, and questions against official fixtures. Encrypt progress into Drift SQLite using owner-scoped AAD. Delete plaintext source only after successful encrypted persistence. Test interrupted migration, active crash between DB commit and deletion, corrupt local record, and missing storage key."*

---

## 4. Independently Verified, Corrected or Rejected AI Suggestion

### The Flawed Suggestion: Timestamp-Derived Idempotency Key
During initial submission outbox planning, the AI model proposed generating the idempotency `operationKey` deterministically from the draft update timestamp and composite string:
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

## 5. Developer Ownership & Accountability
- **Full Engineering Ownership**: The human candidate retains 100% intellectual ownership, design responsibility, and accountability for all code, architectural trade-offs, and technical claims in this repository.
- **Verification Rigor**: Every piece of AI-generated logic was validated against strict automated tests (118 / 118 passing), static analysis (`flutter analyze` with 0 issues), and reproducible compilation (`flutter build apk --debug`).

---

## 6. Privacy & Intellectual Property Affirmation
- **Zero Confidential Leakage**: No private AIRMAN source code, proprietary algorithms, live credentials, production database connections, or real learner data were uploaded, transmitted, or accessed.
- **Synthetic Data Exclusively**: All test accounts (`learner_a`, `learner_b`) and fixtures are synthetic, clearly isolated behind interfaces, and derive exclusively from the official candidate kit fixtures.
