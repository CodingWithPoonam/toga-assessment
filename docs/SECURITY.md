# Security & Cryptographic Architecture
## AIRMAN TOGA Assessment

---

### 1. Data Protection at Rest
- **Algorithm**: AES-GCM-256 authenticated encryption via `cryptography: ^2.9.0`.
- **Master Key**: 256-bit symmetric key generated cryptographically and stored in platform Keystore / Keychain via `flutter_secure_storage`.
- **Ephemeral Access Tokens**: Held exclusively in volatile RAM (`SessionManager`), never written to SQLite, SharedPreferences, or logs.
- **Refresh Credentials**: Encrypted and stored in `flutter_secure_storage`.

---

### 2. Canonical Authenticated Additional Data (AAD)
To prevent ciphertext substitution between learners, lessons, or operation keys, all AES-GCM operations bind the ciphertext to a deterministic, lexicographically sorted canonical JSON string:
```json
{"learnerId":"learner-a","lessonId":"provisional_lesson_1","operationKey":"UUID","revisionId":"rev_1_0"}
```
If an encrypted payload is transferred to another record or modified, AES-GCM authentication tag verification fails with `SecurityException`, rejecting the submission without plaintext fallback.

---

### 3. Multi-Tenant Isolation
- All database queries, outbox operations, and staging transactions enforce tenant boundary checks against `ISessionManager.activeLearnerId`.
- An active learner cannot access, claim, or sync another learner's drafts or outbox submissions.
- `sessionGeneration` monotonicity ensures that late responses from previous accounts cannot mutate the active user interface.
