# Authentication and Session Management Design

- **Module**: `features/auth` and `core/security`
- **Assessment**: AIRMAN TOGA Senior Flutter Assessment
- **Status**: Phase 2 Implementation Complete

---

## 1. Authentication Architecture

The authentication layer follows Clean Architecture with strict layer separation:

```
[UI: LoginPage / Shell]
         │
    (AuthEvent)
         ▼
    [AuthBloc] ◄──── (AuthState)
         │
  (AuthRepository)
         │
   ┌─────┴───────────────────────┐
   ▼                             ▼
[AuthRemoteDataSource]    [ISessionManager]
(Synthetic Fixtures / Dio)       │
                          ┌──────┴──────────────┐
                          ▼                     ▼
                  (Memory: AccessToken)  (ISecureStorage: RefreshToken)
```

1. **Domain Layer**:
   - `Learner`: Non-sensitive display entity (`id`, `displayName`, `email`, `role`).
   - `AuthSession`: Immutable domain session state representation (`learnerId`, `status`, `expiresAt`, `offlineLeaseExpiresAt`, `sessionGeneration`). Never leaks raw tokens to the UI.
   - `AuthRepository`: Business interface for login, session restoration, switching, logout, and offline lease validation.

2. **Data Layer**:
   - `LearnerModel` & `SessionModel`: Strongly typed models with strict JSON validation and error handling.
   - `AuthRemoteDataSource`: Contract with `MockAuthRemoteDataSource` providing isolated synthetic fixtures for `Learner A` and `Learner B`. Fully replaceable with a Dio remote client once the backend API is connected.
   - `AuthRepositoryImpl`: Orchestrates remote authentication, generation checks, and session persistence.

3. **Core Security**:
   - `SessionManager`: Single source of truth for active session state. Access tokens remain solely in memory. Refresh credentials and active learner ID reside in platform secure storage (`EncryptedSharedPreferences` on Android / `Keychain` on iOS).

---

## 2. Session Lifecycle & Token Storage Policy

| Credential | Storage Medium | Lifecycle | Leakage Protection |
|---|---|---|---|
| **Access Token** | Memory (`_accessToken`) | Cleared on app termination, logout, or account switch | Never placed in SharedPreferences, SQLite, or UI state |
| **Refresh Token** | `ISecureStorage` | Persists across app restarts until explicit logout | Encrypted by platform Keystore/Keychain |
| **Active Learner ID** | `ISecureStorage` | Persists to enable offline tenant identification | Non-sensitive, used for lease checking |

---

## 3. Account-Switching Sequence

When switching from Learner A to Learner B:
1. `SessionManager.invalidateSession()` is called immediately:
   - Increments `sessionGeneration`.
   - Clears in-memory `accessToken` to prevent ongoing queries from acting as Learner A.
2. A login call is initiated for Learner B with generation tracking (`switchGen`).
3. Upon response, `SessionManager.isGenerationValid(switchGen)` is validated:
   - If an interleaved operation occurred, the late response is rejected with a `SecurityException`.
4. `SessionManager.setSession(...)` updates `activeLearnerId` to Learner B and writes new refresh credentials.
5. `AuthBloc` emits `AuthAuthenticated(session: Learner B)` without leaking Learner A's cached private data.

---

## 4. Logout Sequence

1. `AuthBloc` receives `LogoutRequested`.
2. Emits `AuthLoading`.
3. Calls remote datasource logout endpoint (best-effort network call with refresh token).
4. Calls `SessionManager.clearAll()` in a `finally` block:
   - Increments `sessionGeneration`.
   - Wipes in-memory `accessToken`.
   - Wipes in-memory `activeLearnerId`.
   - Deletes refresh token and active learner ID from `ISecureStorage`.
5. Emits `AuthUnauthenticated()`.
6. GoRouter redirects automatically to `/login`.

---

## 5. Route Protection (GoRouter Guard)

- `AuthRouterNotifier` listens to `AuthBloc.stream` and notifies GoRouter upon state transitions.
- **Unauthenticated Access**: Direct navigation to `/lessons`, `/quiz`, or `/submission` redirects to `/login`.
- **Authenticated Access**: Navigation to `/login` when already authenticated redirects directly to `/lessons`.
- **Transient States**: `AuthInitial`, `AuthLoading`, and `AuthSwitching` do not trigger premature redirects, preventing flicker and infinite redirection loops.

---

## 6. Offline Session Lease

- The session issues a **24-hour offline lease** (`offlineLeaseExpiresAt = now + 24 hours`).
- While offline, private lesson progress and cached content can be read if `now.isBefore(offlineLeaseExpiresAt)`.
- If the lease expires:
  - `validateOfflineAccess()` returns `false`.
  - Private progress access is locked.
  - User is prompted to re-authenticate with the server.
- The lease is **not extended** merely by restarting the application.

---

## 7. Known Security Limitations & Device Risks

1. **Client-Side Clock Manipulation**: A compromised or maliciously adjusted device clock could falsely indicate that the 24-hour lease is still valid. In production, server timestamp checks and monotonic boot timers (`elapsedRealtime`) should supplement wall-clock validation.
2. **Device Root / Jailbreak**: On rooted Android or jailbroken iOS devices, memory extraction tools could theoretically inspect heap memory to extract in-memory access tokens while the app process is running.
3. **Draft Privacy**: Until encrypted Drift tables are populated in later phases, isolation is enforced logically at the repository and session manager layers.
