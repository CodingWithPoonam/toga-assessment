# TOGA Mobile Delivery Plan: Prototype to Production

## 1. Executive Delivery Strategy & Team Topology
We follow a phased risk-retirement strategy to transition TOGA from an offline-first prototype to enterprise production. Team topology:
- **Mobile Lead (Author)**: Architecture governance, security boundaries, sync engine, release gating.
- **Junior Flutter Engineer 1 (UI/State)**: Lesson catalogue, quiz flows, accessibility, responsive styling.
- **Junior Flutter Engineer 2 (Core/Client Data)**: Drift SQLite migrations, local caching, platform channels.
- **Shared Backend Engineer**: FastAPI contracts, idempotent `/v1/submissions`, token revocation webhooks.
- **QA Engineer**: Offline-to-online scenario automation, network impairment testing, test matrices.

---

## 2. Milestone Roadmap

| Milestone | Scope | Effort | Owner | Dependencies | Exit Evidence & Quality Gate | Release Decision |
|---|---|---|---|---|---|---|
| **M1: Prototype** *(Current)* | Core offline flow: auth, cached lessons, encrypted quiz drafts, durable outbox. | 16h *(Done)* | Mobile Lead | Assessment Brief | 79 unit/bloc/widget tests pass; debug APK builds; 0 analyzer issues. | Internal review only |
| **M2: Engineering Foundation** | FastAPI contract ingestion, integration tests, `WorkManager` background sync, Keystore binding. | 3 Sprints (6 wks) | Team | Official OpenAPI spec & fixtures | E2E integration tests passing on emulator matrix; TLS pinning verified. | Alpha internal dogfooding |
| **M3: Closed Beta** | Staged rollout (5% -> 20%), crash/ANR instrumentation, telemetry, feedback triage. | 2 Sprints (4 wks) | Team | Backend staging env, TestFlight / Google Play Beta | Crash-free sessions >99.5%; outbox sync success rate >99.0%; zero AAD tamper alerts. | Closed Beta signoff |
| **M4: Production Release** | Phased public rollout (10% -> 100%), 24/7 on-call rotation, store approvals. | 2 Sprints (4 wks) | Mobile Lead | Security audit signoff, store compliance | Zero release-blocking P0/P1 incidents over 7 days at 100% distribution. | Executive Go/No-Go |

---

## 3. Architecture & FastAPI Compatibility
The client interfaces with a FastAPI backend via OpenAPI 3.1 contracts. To prevent breaking changes:
1. **Contract Compatibility**: Semantic versioning on endpoints (`/api/v1`). Unknown JSON response fields are ignored by schema models.
2. **Idempotency Guarantee**: Requests carry `X-Operation-Key: <UUIDv4>`. FastAPI persists operation receipts in Redis/Postgres; duplicate keys return identical cached receipts without re-grading.
3. **Draft Migration**: Local Drift SQLite migrations run atomically on launch inside SQLite transactions (`onUpgrade`), maintaining legacy draft integrity without plaintext leakage.

### Engineering Trade-Off Decisions
1. **BLoC + GetIt vs. Riverpod**:
   - *Chosen*: BLoC + GetIt for explicit event streams and lifecycle observability during complex outbox transitions.
   - *Alternative*: Riverpod (simpler scoping).
   - *Revisit Trigger*: If presentation boilerplate demonstrably slows junior feature throughput by >25%.
2. **Foreground-First Bounded Sync vs. Immediate Background Service**:
   - *Chosen*: Foreground sync bounded to 3 attempts / 10s ceiling with lease recovery.
   - *Alternative*: Background headless worker (`WorkManager`).
   - *Revisit Trigger*: If telemetry reveals >5% of submissions remain pending for >24 hours due to immediate app termination.

---

## 4. Platform Build & Release Checklists
- **Android Checklist**: Flavor separation (`dev`, `staging`, `prod`); unique `applicationId` (`org.theairman.toga`); target SDK 35; ProGuard/R8 obfuscation enabled; release keystore stored in CI secrets vault; Google Play 16 KB page-size compliance verified; data safety declarations filed.
- **iOS Checklist**: Bundle ID separation; Fastlane match provisioning with Apple Developer certificate; `NSAppTransportSecurity` enforcing strict TLS 1.3; `kSecAttrAccessibleAfterFirstUnlock` secure storage flag verified; Privacy Manifest (`PrivacyInfo.xcprivacy`) declared.

---

## 5. CI/CD Pipeline & Signing Governance
- **GitHub Actions Pipeline**:
  1. *PR Gate*: `dart format --output=none --set-exit-if-changed`, `flutter analyze --fatal-infos`, `flutter test --coverage`.
  2. *Nightly Build*: Integration tests on Android Emulator and macOS iOS Simulator matrix.
  3. *Release Gate*: Automated semver tagging, changelog generation, release APK/AAB and IPA builds using environment secrets.
- **Governance**: Only Mobile Lead and Release Manager hold production signing keys and Play Console / App Store Connect submission privileges.

---

## 6. Staged Rollout, Telemetry & Stop Criteria
- **Cadence**: 10% (Day 1) -> 25% (Day 3) -> 50% (Day 5) -> 100% (Day 7).
- **Telemetry**: Sentry/Crashlytics (crash-free rates), Datadog (outbox latency, retry distribution).
- **Halt Criteria**: Crash-free sessions <99.0%, ANR rate >0.4%, or sync failure rate >2.0%.
- **Installed Version Mitigation**: Rollout halt stops new downloads. For installed clients: dynamic remote feature flags disable broken quiz modules, redirecting learners to offline cached reading while forward-fix patches deploy.

---

## 7. Incident Response: First 30 Minutes
- **T+0 to T+5m (Containment)**: On-call engineer halts active store rollout. Engage kill-switch flag if backend is destabilized.
- **T+5 to T+15m (Triage & Isolation)**: Inspect error signatures in Sentry. Determine whether failure is client crypto/storage corruptions or server 5xx. Isolate affected app versions.
- **T+15 to T+25m (Stakeholder Escalation)**: Notify Mobile Lead and VP Engineering with blast radius, confirmed facts, and working hypotheses.
- **T+25 to T+30m (Remediation Path)**: Decide between backend patch, feature flag toggle, or expedited hotfix build.
- **Handover & Follow-Up**:
  - *Handover*: Brief customer support with customer-safe guidance (advising learners *not* to clear app storage to preserve encrypted drafts).
  - *Follow-ups*: Root Cause Analysis (RCA) post-mortem (signal: signed post-mortem document); automated regression test added to CI suite (signal: merged PR).
