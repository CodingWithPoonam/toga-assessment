# Lessons, Quiz, and Durable Offline Progress Architecture

- **Phase**: 3A Implementation
- **Assessment**: AIRMAN TOGA Senior Flutter Developer Assessment
- **Status**: Complete & Verified

---

## 1. Feature Architecture

```
[UI: LessonsPage / LessonDetailPage / QuizPage]
                   │
            (Typed BLoC Events)
                   ▼
       [LessonBloc] / [QuizBloc]
                   │
            (Repositories)
         ┌─────────┴─────────┐
         ▼                   ▼
 [LessonRepository]   [QuizRepository]
         │                   │
   ┌─────┴──────┐     ┌──────┴──────┐
   ▼            ▼     ▼             ▼
[LocalDS]  [FixtureDS] [LocalDS] [FixtureDS]
 (Drift)    (Synthetic) (Drift + AES)
```

1. **Lesson Catalogue**:
   - `LessonBloc` coordinates catalog retrieval and detail view.
   - Durably caches content into Drift SQLite `CachedLessons`.
   - `isCached` is only `true` when content is successfully committed and retrieved from SQLite.
2. **Interactive Quiz**:
   - `QuizBloc` orchestrates 5 multiple-choice questions per lesson.
   - Question position tracking and answered/unanswered indicators.
   - Pinned revision model: the quiz draft remains locked to the exact content revision with which it started.
3. **Decoupled Security**:
   - Answer choices are encrypted with AES-GCM-256 (`IEncryptionService`) before writing to SQLite.
   - Plaintext answer options never touch disk.
   - All private progress is strictly namespaced by the active, verified `learnerId` from `SessionManager`.

---

## 2. Lesson Revision Strategy

1. **Decoupled Identity**:
   - `lessonId`: Stable identity across updates (e.g. `provisional_lesson_1`).
   - `revisionId`: Unique revision identifier (e.g. `rev_1_0`).
2. **Revision Pinning**:
   - A newly started quiz draft records `revisionId` in `QuizDrafts.revisionId`.
   - Subsequent answer selections and question navigations update this pinned draft.
3. **Stale Content & Mismatch Detection**:
   - If the remote server or local catalogue updates to a newer revision (e.g. `rev_2_0`), `QuizBloc` detects `existingDraft.revisionId != event.revisionId`.
   - Rather than silently remapping answers or corrupting the draft, it emits `QuizRevisionMismatch`.
   - The UI presents an explicit dialog:
     - **Keep Draft**: Learner continues and finishes the draft pinned to the previous revision.
     - **Start Fresh**: Clears the draft and begins the quiz on the new revision.

---

## 3. Atomic Draft Persistence & Encryption

1. **Database Schema**:
   - `QuizDrafts`: Contains draft ID (`${learnerId}_${lessonId}`), `learnerId`, `lessonId`, `revisionId`, `currentQuestionIndex`, `updatedAt`.
   - `QuizAnswers`: Foreign key to `QuizDrafts.id` with cascading delete. Stores `questionId` and `encryptedSelectedOptionId`.
2. **Encryption Boundary**:
   - `QuizLocalDataSource` encrypts `selectedOptionId` using `IEncryptionService.encrypt(optionId)` (AES-GCM-256 with fresh 96-bit nonce).
   - Only decrypted into memory when `getDraft()` is queried.
3. **Atomic Transactions**:
   - Every answer save executes inside `database.transaction(...)`.
   - If either draft row or answer row fails, SQLite rolls back the entire change, preventing partial drafts.

---

## 4. Learner Isolation

- `QuizRepositoryImpl` extracts `activeLearnerId` strictly from `ISessionManager.activeLearnerId`.
- It never trusts a learner ID passed from UI route parameters or widget properties.
- When switching between Learner A and Learner B:
  - Learner A's draft is keyed to `learner-a_provisional_lesson_1`.
  - Learner B's draft is keyed to `learner-b_provisional_lesson_1`.
  - Switching accounts completely isolates answers; neither learner sees or overwrites the other's draft.

---

## 5. Process Termination and Recovery Sequence

1. **Simulated Crash/Termination**:
   - Learner answers Q1 and Q2, moves to Q3.
   - App is abruptly stopped or BLoC recreated.
2. **Recovery**:
   - On app restart, `AuthBloc.restoreSession()` restores the active learner.
   - When the learner re-opens the lesson quiz, `QuizBloc.StartQuiz` queries `QuizRepository.getDraft(lessonId)`.
   - Draft is retrieved from SQLite, answers decrypted, and `QuizInProgress` emitted with:
     - Same question position (Q3).
     - Same answers (Q1 and Q2 populated).
     - Same pinned revision.

---

## 6. Known Limitations (Phase 3A)

1. **Client-Side Scoring Omitted**: In accordance with the assessment brief, no client-side calculated scores are presented as official results. Final score grading belongs to server synchronisation.
2. **Outbox Submission Deferred**: Submission outbox and sync with conflict resolution belong to Phase 3B/Sync phase.
