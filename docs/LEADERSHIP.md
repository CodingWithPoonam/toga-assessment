# Technical Leadership, Team Guidance & Incident Management

## 1. Iteration Planning (Sprint Backlog)
Four ordered two-week iteration tickets for closed beta readiness:
1. **TOGA-101: Native Keystore / Keychain Hardware Key-Wrap Integration**  
   *Owner*: Junior Engineer 2 | *Reviewer*: Mobile Lead  
   *Outcome*: Secure AES key storage using Android KeyStore & iOS Keychain HSM.  
   *Dependency*: None | *Acceptance Evidence*: Passing unit tests verifying key generation and fallback rejection.
2. **TOGA-102: Lesson Markdown Renderer & Dynamic Typography**  
   *Owner*: Junior Engineer 1 | *Reviewer*: Mobile Lead  
   *Outcome*: Accessible lesson rendering supporting dynamic scaling (200%) and dark mode.  
   *Dependency*: Lesson repository | *Acceptance Evidence*: Golden widget tests for screen sizes 320dp to 768dp.
3. **TOGA-103: OS Background Sync Worker via WorkManager**  
   *Owner*: Junior Engineer 2 | *Reviewer*: Mobile Lead  
   *Outcome*: Headless background trigger invoking `GetIt<ISyncEngine>()` on reconnect.  
   *Dependency*: TOGA-101 | *Acceptance Evidence*: Outbox drain verified in battery-saver mode.
4. **TOGA-104: OpenAPI 3.1 Contract Ingestion & Mock Adapter Swap**  
   *Owner*: Shared Backend + Mobile Lead | *Reviewer*: QA Engineer  
   *Outcome*: Verified serialization against production FastAPI `/v1/submissions`.  
   *Dependency*: Backend staging deploy | *Acceptance Evidence*: Zero contract mismatch errors in CI matrix.

---

## 2. Ownership & Delegation
- **Lead Ownership**: Security boundaries, SQLite schema evolution, cryptographic AAD, sync engine idempotency.
- **Delegation**: Feature layouts, widget tests, and platform packaging are delegated with strict interface contracts.
- **Unblocking Example**: Paired with a junior experiencing SQLite test locking; resolved by demonstrating Drift's in-memory executor pooling.

---

## 3. Code Reviews (Supplied Flawed Excerpts)
*(Raw excerpts withheld from workspace materials; reviews address canonical assessment design risks [PROVISIONAL_EXCERPT_PLACEHOLDER]).*

### Review 1: Lifecycle & Stale Rebuild (`QuizView.dart`)
> **Comment**: "Reading `context.read<AuthBloc>()` across an async gap without account validation risks rendering stale data.  
> **Consequence**: Cross-account data leakage in the UI if the learner switches mid-flight.  
> **Correction**: Bind to `BlocConsumer` and verify `state.activeLearnerId == currentLearnerId`.  
> **Teaching Question**: How does the event-loop microtask queue affect widget state when a route pops mid-await?"

### Review 2: Security & Token Storage (`AuthService.dart`)
> **Comment**: "Writing ephemeral access tokens to `SharedPreferences` exposes credentials on rooted devices and OS backups.  
> **Consequence**: Token exfiltration without sandbox protection.  
> **Correction**: Retain access tokens in memory (`SessionManager`), storing only refresh tokens in secure storage.  
> **Teaching Question**: Why does in-memory scoping minimize backup exfiltration risk?"

---

## 4. Coaching on Submission Idempotency
When a junior proposed clearing the queue before calling the API and generating a new UUID on retry:
1. **Pair on a Failing Test**: Simulate dropped connection after server acceptance.
2. **Demonstrate Failure**: The new UUID causes duplicate evaluation; early queue clearance destroys unacknowledged submissions.
3. **Resolve Constructively**: Walk through RFC 4122 v4 keys and atomic SQLite commits to align on data durability.

---

## 5. Founder Incident Update (Max 120 Words)
> "At 14:15 UTC, mobile release v1.2.0 exhibited submission sync failures impacting 45 active learners. **Impact**: Submitted quizzes remain safely pending locally; zero learner data was lost due to encrypted SQLite persistence. **Unknowns**: Investigating backend schema changes vs. client lease expirations. **Containment**: Rollout halted at 0%; app kill-switch activated to pause retries and preserve battery. **Ownership**: Mobile Lead (Incident Commander). **Next Update**: 15:00 UTC with root-cause confirmation and hotfix schedule."

---

## 6. Privacy, Deferred Features & AI Governance
- **QA/Support Privacy**: Test accounts use synthetic fixtures; production telemetry strips PII, tokens, and quiz answers.
- **Deferred Feature**: Live leaderboards deferred until outbox stability exceeds 99.9% across 10,000 sessions.
- **AI Governance**: AI suggestions require manual verification, 100% test coverage, and human lead accountability.
