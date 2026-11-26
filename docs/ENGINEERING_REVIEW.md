# Engineering Review & Architectural Trade-offs
## AIRMAN TOGA Assessment

---

### 1. Architectural Decisions

| Decision | Rationale | Alternatives Considered |
|---|---|---|
| **Dedicated `SubmissionOutbox` table** | Explicitly models quiz submission lifecycle, avoiding premature generic abstraction while guaranteeing strict schema types. | Generic mutation table (rejected: loose typing, harder diagnostics). |
| **RFC 4122 v4 UUID `operationKey`** | Guarantees global uniqueness for idempotency, persisted on initial staging and reused across all retries. | Timestamp-derived key (rejected: risk of collisions and timestamp skew). |
| **Strict revision pinning** | Ensures client never silently substitutes newer content; server evaluates whether completed attempt is valid. | Automatic answer remapping (rejected: corrupts pedagogical validity). |
| **Atomic SQLite transactions** | Guarantees all-or-nothing staging and acknowledgement without orphan records. | In-memory mutex (rejected: vulnerable to app crashes and process kills). |
| **Shared `AuthInterceptor` single-flight refresh** | Avoids redundant refresh calls during concurrent 401 responses. | Refresh logic in `SyncEngine` (rejected: duplicates networking concerns). |

---

### 2. Residual Risks & Next Steps
- **Background Execution**: Platform-specific background tasks (e.g. `WorkManager`) should reuse `ISyncEngine` and the durable outbox claim mechanism without altering business logic.
- **Official AIRMAN API Contracts**: Once official schemas and endpoints are provided, replace `MockSyncRemoteDataSource` without altering the Clean Architecture domain or presentation layer.
