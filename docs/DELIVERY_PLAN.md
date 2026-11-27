# TOGA Mobile Delivery Plan: Prototype to Production

## 1. Executive Delivery Strategy & Incident Realignment
We follow an evidence-based risk-retirement model to transition TOGA from candidate prototype to enterprise release. 

### Telemetry & Incident Analysis (Build beta_18 Rollout)
Field telemetry from `data/incident_observations.csv` captured between 10:00 and 10:30 IST across `prototype_17` and `beta_18` reveals critical operational regressions:
- **Session Volume**: Grew from 80 sessions (`prototype_17` baseline at 10:00) to 95 sessions (`beta_18` at 10:30), an 18.75% increase (+15 sessions).
- **Crash Rate**: Crash-free sessions dropped from **98.8%** (79/80) down to **92.6%** (88/95) across 30 minutes. Absolute crashes rose from 1 to 7 (a 600% increase, 7x).
- **Auth Refresh Storm**: Auth refresh calls surged from **12** to **205** (+193 calls, a 1608.3% increase / ~17.1x). The log documents "login loops on resume", directly reflecting recursive 401 refresh storms (`review/legacy_auth.dart:21-27`).
- **Sync Queue Backlog**: Pending outbox reports escalated from **2** to **26** (+1200% / 13x), indicating stalled transmissions or premature lease expirations under poor cellular links.
- **Symbolicated Error**: Telemetry symbolic sample confirmed `setState called after dispose`, matching unmanaged stream subscriptions (`review/legacy_study_page.dart:16`).
- **Account Isolation**: A single unverified report noted "previous learner name after account switch" at 10:25 (84/90 crash-free).

### What the Data Cannot Establish
Rigorous engineering governance requires distinguishing facts from hypotheses:
1. The aggregate CSV data shows strong temporal correlation with `beta_18`, but **cannot prove direct causality** between specific code commits and individual crashes without symbolicated stack trace volume breakdowns.
2. The learner name leakage remains explicitly an **unverified report**; the telemetry data cannot establish whether this stemmed from client UI caching, a race during delayed fetch, or server-side session aliasing.
3. The sync backlog does not establish whether submissions were permanently dropped or temporarily buffered offline awaiting reconnect.

---

## 2. Milestone Roadmap

| Milestone | Scope | Effort | Owner | Dependencies | Exit Evidence & Quality Gate | Release Decision |
|---|---|---|---|---|---|---|
| **M1: Assessment Prototype** *(Current)* | Core offline flow: auth, cached lessons, encrypted quiz drafts, durable outbox. | Done | Mobile Lead | Candidate Kit | 118 unit/widget/integration tests pass; debug APK builds; 0 analyzer issues. | Assessment signoff |
| **M2: Reliability Hardening** | Single-flight refresh mutex, generational BLoC guards, lease recovery, Keystore HSM key wrap. | 3 Sprints (6 wks) | Mobile Team | OpenAPI spec & fixtures | Zero recursive refresh calls; E2E integration tests passing on emulator matrix; TLS 1.3 verified. | Internal alpha |
| **M3: Staged Beta Rollout** | Canary rollout (5% $\to$ 20%), Sentry/Crashlytics monitoring, outbox latency telemetry. | 2 Sprints (4 wks) | Mobile Team | Staging environment | Crash-free sessions >99.5%; outbox sync success >99.0%; zero `setState` leaks. | Closed beta gate |
| **M4: Production Deployment** | Phased public release (10% $\to$ 100%), automated kill-switch, store approvals. | 2 Sprints (4 wks) | Mobile Lead | Store compliance | Zero P0/P1 incidents over 7 days at 100% rollout; Play Console approval. | General Availability |

---

## 3. Architecture & Reliability Improvements
Prioritized engineering mitigations directly addressing observed incident patterns:
1. **Single-Flight Refresh Mutex**: `AuthInterceptor` coalesces concurrent 401s into a single refresh request, halting login loops and refresh storms.
2. **Generational BLoC Barriers**: Monotonic counters (`_activeDetailGeneration`, `sessionGeneration`) discard delayed microtasks on route departure or account switch, preventing stale state overwrites.
3. **Durable Lease-Locked Outbox**: Atomic Drift SQLite transactions transition records (`pending` $\to$ `in_flight` $\to$ `completed`), preventing premature queue erasure and double submission.
4. **Accessible Wrap Layouts**: Responsive chip wrapping guarantees zero RenderFlex overflows on narrow $320\text{px}$ screens under 200% font scaling.

---

## 4. CI/CD Pipeline & Signing Governance
- **GitHub Actions Gates**:
  1. *PR Gate*: `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos`, `flutter test --coverage` (100% pass required).
  2. *Nightly Build*: Android debug compilation and integration tests on synthetic fixtures.
- **Signing Governance**: Production keys and keystores remain secured in hardware security modules / cloud vaults; local development strictly restricted to debug keys.

---

## 5. Incident Response & Containment Protocol
When telemetry alerts fire (crash-free rate <99.0% or refresh call surge >5x baseline):
1. **T+0 to T+5m**: Freeze rollout; engage client kill-switch to halt outbox polling and conserve battery.
2. **T+5 to T+15m**: Triage telemetry. Inspect whether failures are platform crypto faults, unmanaged stream leaks, or backend 5xx.
3. **T+15 to T+25m**: Determine remediation: backend configuration patch, feature flag toggle, or emergency hotfix.
4. **T+25 to T+30m**: Communicate blast radius to leadership. Advise user support that learners must *not* wipe app storage, preserving encrypted drafts for automatic sync upon forward-fix.
