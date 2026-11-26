# Security Architecture & Threat Model

## 1. Data-Flow Diagram (DFD)

```mermaid
flowchart TD
    subgraph ClientDevice ["Untrusted Mobile Host (Android / iOS)"]
        subgraph Memory ["Volatile RAM"]
            AT["Access Token (Ephemeral)"]
            SM["SessionManager (Generation Counter)"]
            Key["AES-256 Symmetric Key"]
        end
        subgraph SecureStorage ["Platform Secure Enclave"]
            RT["Refresh Token"]
            MK["Wrapped Master Key"]
        end
        subgraph LocalDisk ["App Sandbox Storage"]
            DB[("Drift SQLite Database")]
            subgraph EncryptedTables ["Encrypted At Rest (AES-GCM-256)"]
                QD["QuizDrafts / Answers"]
                OB["SubmissionOutbox (UUIDv4)"]
            end
        end
    end

    subgraph RemoteBackend ["FastAPI Backend (Cloud)"]
        API["API Gateway / v1"]
        AuthSvc["Auth Service"]
        OutboxSvc["Idempotent Submission Service"]
    end

    AT -->|Bearer Auth (HTTPS)| API
    RT <-->|Rotate Credentials| AuthSvc
    QD -->|Canonical AAD Encryption| DB
    OB -->|X-Operation-Key| OutboxSvc
    MK -->|Decrypt into RAM| Key
```

---

## 2. Five Prioritized Security Threats

### Threat 1: Cross-Tenant Data Leakage via Account Switching
- **Asset**: Learner private quiz progress, answers, and pending outbox records.
- **Attack Path**: Learner A leaves device unlocked; Learner B logs in. Uncancelled in-flight requests or shared caches leak Learner A's answers to Learner B.
- **Mitigation (Implemented)**: All queries filter by `activeLearnerId`. On logout, `ResetQuiz` is dispatched, and `SessionManager` increments a monotonic `sessionGeneration` counter, discarding callbacks from previous generations.
- **Verification Test**: `test/unit/features/sync/sync_engine_test.dart` ("Logout during upload prevents cross-account mutation").
- **Residual Risk**: Rooted devices sharing memory across processes; mitigated in production via root detection.

### Threat 2: Credential Extraction from Storage Backups
- **Asset**: OAuth2 access and refresh tokens.
- **Attack Path**: Attacker extracts unencrypted `SharedPreferences` or database backups via ADB/iCloud.
- **Mitigation (Implemented)**: Access tokens exist strictly in volatile memory. Refresh tokens are stored via `flutter_secure_storage` using OS Keychain/KeyStore.
- **Verification Test**: `test/unit/core/security/session_manager_test.dart` ("Access token remains in memory").
- **Residual Risk**: Physical memory dump on compromised jailbroken kernels.

### Threat 3: Ciphertext Swapping & Submission Tampering
- **Asset**: Outbox submission payload integrity and learner attribution.
- **Attack Path**: Attacker copies Learner A's encrypted payload into Learner B's outbox row to forge authorship.
- **Mitigation (Implemented)**: AES-GCM-256 authenticated encryption binds ciphertext to canonical JSON AAD `{"learnerId":...,"lessonId":...,"operationKey":...,"revisionId":...}`. Any field tampering causes MAC authentication failure with `SecurityException`.
- **Verification Test**: `test/unit/core/security/encryption_service_test.dart` ("AAD mismatch throws SecurityException").
- **Residual Risk**: Compromise of the local AES key allows re-encryption.

### Threat 4: Outbox Replay & Duplicate Submission
- **Asset**: Quiz scoring integrity and server grading resources.
- **Attack Path**: Attacker captures submission HTTP requests and replays them, or rapid client taps trigger duplicate submissions.
- **Mitigation (Implemented)**: RFC 4122 v4 UUID `operationKey` is persisted atomically during staging and sent via `X-Operation-Key`. Server processes each key once idempotently.
- **Verification Test**: `test/unit/features/sync/sync_repository_test.dart` ("Duplicate staging requests reuse identical operation key").
- **Residual Risk**: Client clock manipulation does not break UUIDv4 uniqueness.

### Threat 5: Key Loss and Corrupt Local Storage
- **Asset**: Database recoverability.
- **Attack Path**: App crash or secure storage corruption renders stored drafts unreadable.
- **Mitigation (Implemented)**: Corrupt ciphertext throws explicit `SecurityException` without crashing; system refuses plaintext fallback and alerts the learner to re-attempt.
- **Verification Test**: `test/unit/features/sync/sync_engine_test.dart` ("Key failure causes no plaintext fallback").
- **Residual Risk**: Unsynchronized local progress is unrecoverable if the master key is permanently erased.

---

## 3. Production Hardening Requirements
- **Hardware Keystore Binding**: Explicitly configure `encryptedSharedPreferences: true` (Android) and `kSecAttrAccessibleAfterFirstUnlock` (iOS).
- **Certificate Pinning**: Enforce TLS public key pinning against `api.theairman.org`.
- **Supply-Chain Audit**: Automate `dart pub audit` in CI to detect vulnerable dependencies.
