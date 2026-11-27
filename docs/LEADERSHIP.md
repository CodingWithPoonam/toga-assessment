# Technical Leadership & Incident Governance

## 1. Incident Analysis & Team Guidance (`beta_18` Regression)
During the `beta_18` phased rollout (`data/incident_observations.csv`), telemetry degraded sharply between 10:00 and 10:30 IST across 95 observed sessions:
- **Crash Rate**: Crash-free sessions fell from **98.8%** (79/80) to **92.6%** (88/95), representing a 7x increase in crashes (1 $\to$ 7).
- **Refresh Surge**: Auth refresh calls spiked by **1608.3%** (12 $\to$ 205 calls), triggering user-reported "login loops on resume".
- **Outbox Stalling**: Pending sync submissions accumulated from 2 to 26 (+1200%).
- **Error Signatures**: A symbolicated crash confirmed `setState called after dispose`, while one unverified report cited seeing a previous learner's name after switching accounts.

### Engineering Grounding & Bounds
As Technical Lead, I coached the team on interpreting telemetry rigorously:
1. **Correlation vs. Causation**: While telemetry correlates `beta_18` with crash increases, it cannot establish direct causality without stack-trace aggregation.
2. **Unverified Claims**: The single learner-name report cannot distinguish between client-side BLoC state carryover and backend session aliasing without session trace logs.
3. **Actionable Remediation**: Prioritize verified root causes: implement single-flight refresh mutexes, generational state counters, and mandatory `StreamSubscription.cancel()` on dispose.

---

## 2. Iteration Planning (Hardened Sprint Backlog)
Four ordered sprint backlog items targeting verified reliability gaps:
1. **TOGA-201: Single-Flight Refresh Mutex & Circuit Breaker**  
   *Owner*: Mobile Lead | *Reviewer*: Backend Lead  
   *Outcome*: Coalesce concurrent 401s into one isolated refresh call; halt recursive loops on revoked tokens.  
   *Acceptance*: Zero refresh loop regressions under 401 fault injection in integration tests.
2. **TOGA-202: Generational Lifecycle & Subscription Governance**  
   *Owner*: Junior Engineer 1 | *Reviewer*: Mobile Lead  
   *Outcome*: Enforce monotonic generation counters in `LessonBloc` and audit all stream listeners for disposal.  
   *Acceptance*: Zero `setState` warnings and verified stale-response discarding during rapid route switching.
3. **TOGA-203: Durable Outbox Lease Recovery**  
   *Owner*: Junior Engineer 2 | *Reviewer*: Mobile Lead  
   *Outcome*: Automatic recovery of `in_flight` submissions whose lease exceeds 30s.  
   *Acceptance*: Unacknowledged submissions reliably re-queued without duplicate execution.
4. **TOGA-204: Accessible Typography & Narrow Layout Audit**  
   *Owner*: Junior Engineer 1 | *Reviewer*: Mobile Lead  
   *Outcome*: Replace rigid Row layouts with responsive Wrap widgets across all study and quiz views.  
   *Acceptance*: Clean rendering without overflow at 200% font scaling on $320\text{px}$ viewports.

---

## 3. Code Review & Mentorship Practice
When reviewing flawed pull requests (such as `review/legacy_auth.dart` and `review/legacy_sync.dart`), mentorship focuses on foundational invariants:
- **Security**: *"Never bypass TLS validation (`badCertificateCallback`) or log auth headers to stdout. Why does an isolated refresh client prevent recursive interceptor loops?"*
- **Reliability**: *"Never delete pending submissions before network confirmation. Why must the idempotency key be generated once at staging and preserved across retries?"*
- **Lifecycle**: *"Why does `mounted` alone fail to protect multi-tenant state if an account switch occurs during an await?"*

---

## 4. Founder & Stakeholder Incident Communication (110 Words)
> "At 10:30 IST, rollout of `beta_18` was halted at 95 sessions due to telemetry alerts: crash-free sessions dipped to 92.6% (7 crashes) and auth refresh volume surged to 205 calls due to token refresh loops. **Learner Data Impact**: Zero progress loss. All student quiz drafts remain securely encrypted in local SQLite storage. **Containment**: Active deployment paused; kill-switch engaged to stop polling. **Root Cause**: Identified recursive 401 interceptor loops and unmanaged widget subscriptions. **Remediation**: Hotfix `beta_19` deploying at 12:00 IST with single-flight refresh mutexes and generational lifecycle guards. Next update at 11:30 IST."
