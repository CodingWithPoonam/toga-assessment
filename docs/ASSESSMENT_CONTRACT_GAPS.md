# Assessment Contract Gaps and Provisional Fixture Specification

- **Status**: Documented & Tracked
- **Date**: 2026-11-26
- **Context**: AIRMAN TOGA Senior Flutter Assessment (Phase 3A)
- **Tag**: `PROVISIONAL_DEVELOPMENT_FIXTURE_NOT_OFFICIAL_AIRMAN_DATA`

---

## 1. Context and Problem Statement

The AIRMAN assessment specification outlines:
1. Two supplied lessons with revision tracking.
2. A five-question multiple-choice quiz.
3. Durable offline progress with learner isolation.
4. Lesson revision handling and recovery from stale content.
5. Cached lesson reading.

However, the standalone official lesson JSON files, question fixture assets, and remote API contracts have not been provided in the repository workspace.

---

## 2. Identified Contract Gaps

| Contract Area | Missing Official Material | Provisional Development Assumption |
|---|---|---|
| **Lesson Catalogue** | Official lesson IDs, titles, body content, estimated reading durations, and multimedia assets | Two synthetic lessons: `provisional_lesson_1` and `provisional_lesson_2` with structured Markdown bodies |
| **Lesson Revision Identity** | Official revision format (e.g. integer increment, UUID, or semantic hash) and revision change detection endpoint | A string revision field `revisionId` (e.g. `rev_1_0_initial` and `rev_2_0_updated`) decoupled from lesson ID |
| **Quiz Questions** | Official 5-question fixture, question IDs, option IDs, question weights, explanations | Five synthetic multiple-choice questions (`q1`–`q5`) with stable option IDs (`opt_a`–`opt_d`) |
| **Stale Content Protocol** | Server error format for `STALE_CONTENT` and resolution flow (e.g. discard vs merge draft) | Explicit repository method and UI prompt requiring user confirmation to restart or retain draft on revision bump |
| **Remote Endpoints** | Exact HTTP REST/GraphQL paths, headers, and pagination schemas for lessons and drafts | Repository abstractions (`LessonRepository`, `QuizRepository`) backed by `LessonLocalDataSource` and provisional in-memory remote sources |

---

## 3. Provisional Synthetic Fixtures

All synthetic fixtures in the codebase are explicitly annotated with:
`PROVISIONAL_DEVELOPMENT_FIXTURE_NOT_OFFICIAL_AIRMAN_DATA`

### Lesson Fixtures
- **Lesson 1**:
  - ID: `provisional_lesson_1`
  - Revision: `rev_1_0`
  - Title: `Aerodynamics & Flight Principles`
  - Summary: `Fundamental lift, drag, thrust, and gravity concepts in modern aviation.`
- **Lesson 2**:
  - ID: `provisional_lesson_2`
  - Revision: `rev_1_0`
  - Title: `Aircraft Instruments & Navigation Systems`
  - Summary: `Altimeters, gyroscopes, pitot-static systems, and VHF omnidirectional ranges.`

### Quiz Fixtures (Lesson 1)
- Exactly 5 multiple-choice questions with 4 options each:
  - `q1`: Primary force counteracting aircraft weight (Lift).
  - `q2`: Bernoulli's principle relationship between airspeed and pressure.
  - `q3`: Function of the pitot tube.
  - `q4`: Control surface governing aircraft pitch (Elevators).
  - `q5`: Angle of attack definition and stall conditions.

---

## 4. Replacement Strategy

1. **Repository Abstraction**: All Flutter widgets and BLoCs interact exclusively with `LessonRepository` and `QuizRepository`.
2. **Encrypted Persistence Boundary**: Drift tables store encrypted draft payloads regardless of question schema.
3. **Seamless Migration**: When official JSON files or REST API specs are supplied, only `LessonFixtureDataSource` and remote data source parsers need to be updated. No UI, routing, state management, or cryptographic code will need to be rewritten.
