# Assessment Contract Gaps and Provisional Fixture Specification
## AIRMAN TOGA Senior Flutter Assessment (Phases 3A & 3B)

- **Status**: Documented & Tracked
- **Date**: November 2026
- **Tag**: `PROVISIONAL_DEVELOPMENT_FIXTURE_NOT_OFFICIAL_AIRMAN_DATA`

---

## 1. Context and Problem Statement

The AIRMAN assessment specification outlines:
1. Two supplied lessons with revision tracking.
2. A five-question multiple-choice quiz.
3. Durable offline progress with learner isolation.
4. Lesson revision handling and recovery from stale content.
5. Cached lesson reading.
6. Durable submission outbox and background synchronization.

However, official lesson JSON files, question fixture assets, submission REST schemas, and server-side grading contracts have not been provided in the repository workspace.

---

## 2. Identified Contract Gaps & Provisional Assumptions

| Contract Area | Missing Official Material | Provisional Development Assumption |
|---|---|---|
| **Lesson Catalogue** | Official lesson IDs, titles, body content, reading durations | Synthetic lessons: `provisional_lesson_1` and `provisional_lesson_2` |
| **Lesson Revision Identity** | Official revision format and bump detection | String revision field `revisionId` (`rev_1_0`) decoupled from lesson ID |
| **Quiz Questions** | Official 5-question fixture, option weights, grading rules | Five synthetic multiple-choice questions (`q1`–`q5`) with stable option IDs |
| **Sync Submission API** | Official HTTP endpoints, request body schemas, header specifications | Idempotency header `X-Operation-Key: <UUID>` and `MockSyncRemoteDataSource` |
| **Server Acknowledgement** | Official receipt schema and digital signature format | `SyncSubmissionResponse` with `receiptId`, `operationKey`, and `acknowledgedAt` |
| **Server-Side Grading** | Official grading API endpoints and scoring algorithms | **No client-side authoritative grading invented**. Client only coordinates submission outbox and persists server receipts |

---

## 3. Replacement Strategy

1. **Repository & Datasource Abstractions**: UI widgets, BLoCs, and `SyncEngine` communicate solely through `SyncRepository` and `QuizRepository`.
2. **Encrypted Snapshot Boundary**: Drift SQLite stores encrypted submission snapshots regardless of remote payload format.
3. **Pluggable Remote Adapter**: When official AIRMAN backend endpoints are supplied, only `SyncRemoteDataSource` needs to be adapted. Zero BLoC, SQLite, or UI code will require refactoring.
