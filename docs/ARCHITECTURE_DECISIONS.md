# Architecture Decision Record (ADR)

## ADR 001: State Management and Dependency Injection Strategy

- **Status**: Accepted
- **Date**: 2026-11-26
- **Context**: AIRMAN TOGA Senior Flutter Assessment

---

### Context and Problem Statement

The assessment involves building an offline-first, secure educational application with complex workflows:
1. Session and token lifecycle management.
2. Learner lesson exploration and offline progress caching.
3. Event-driven interactive quizzes with client-side timers, draft auto-saving, and encrypted snapshots.
4. Resilient background/foreground synchronisation outbox with retry backoff and conflict resolution.

While Riverpod is commonly preferred in smaller codebases for its concise provider declarations and compile-time safety, this assessment requires explicit architectural boundaries, auditability of state transitions, strict layer separation, and resilient offline lifecycle handling.

---

### Decision

**Selected Architecture**: `flutter_bloc` for state management paired with `get_it` for dependency injection.

**Assessment Baseline Preference**: Riverpod.

---

### Justification for Selected Approach

1. **Explicit Event and State Transitions**
   - The assessment's core business domains (such as quiz progression, session re-authentication, and submission sync outbox) are fundamentally event-driven.
   - BLoC requires every action to be a typed event and every output to be an immutable state, preventing accidental side-effects or uncontrolled state mutation.

2. **Observability and Testability**
   - BLoC state transitions are easily logged via `BlocObserver` and deterministically tested using `bloc_test`.
   - Each state transition is explicit: `Event -> Process -> New State`, making regression tracking and event replay straightforward.

3. **Separation of Concerns via GetIt**
   - `get_it` provides explicit service locator and dependency injection decoupled from the Flutter widget tree.
   - Infrastructure services (encrypted storage, SQLite database, secure HTTP client) can be initialized asynchronously prior to UI rendering, avoiding widget-tree context coupling.
   - Mocking and overriding singletons or factories in automated unit and integration tests is clean and direct.

4. **Trade-offs**
   - **Boilerplate**: BLoC requires dedicated Event and State classes along with manual registration in `GetIt`.
   - **Explicit Registration**: Unlike Riverpod where dependencies are scoped and discovered automatically, `GetIt` requires careful registration order and disposal handling.

5. **Role of Riverpod as an Alternative**
   - Riverpod remains a powerful and valid architecture choice, especially when fast dependency injection without a service locator is desired.
   - Riverpod can simplify provider dependencies and eliminate locator lookup mistakes at runtime.

---

### Critical Architectural Principle

**State management alone does not guarantee data consistency, security, or offline reliability.**

Neither BLoC nor Riverpod inherently solves:
- Atomic database transactions across offline drafts and sync outboxes.
- Cryptographic key isolation and credential security.
- Network idempotency and outbox synchronization resilience.
- Learner progress boundary isolation.

These responsibilities are owned by the underlying Clean Architecture layers:
- **Core Security Layer**: AES-GCM-256 encryption, secure keystore storage.
- **Data Persistence Layer**: Drift SQLite with transactional migrations and outbox journaling.
- **Domain Repositories & Use Cases**: Business rules, error mapping, and validation.
