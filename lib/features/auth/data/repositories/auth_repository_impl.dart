import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/session_manager.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of AuthRepository managing tokens, lease checks, and session transitions
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final ISessionManager sessionManager;
  final DateTime Function() _clock;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.sessionManager,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  @override
  Future<AuthSession> login({
    required String learnerId,
    required String password,
  }) async {
    final startGen = sessionManager.sessionGeneration;
    try {
      final sessionModel = await remoteDataSource.login(
        learnerId: learnerId,
        password: password,
      );

      // Verify no concurrent session transition occurred during remote call
      if (!sessionManager.isGenerationValid(startGen)) {
        throw const SecurityException(
          'Concurrent authentication operation detected',
        );
      }

      await sessionManager.setSession(
        learnerId: sessionModel.learner.id,
        accessToken: sessionModel.accessToken,
        refreshToken: sessionModel.refreshToken,
      );

      return sessionModel.toEntity(
        generation: sessionManager.sessionGeneration,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure('Authentication failed: $e');
    }
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final refreshToken = await sessionManager.getRefreshToken();
    final persistedLearnerId = await sessionManager.getPersistedLearnerId();

    if (refreshToken == null || persistedLearnerId == null) {
      return null;
    }

    final startGen = sessionManager.sessionGeneration;
    try {
      final sessionModel = await remoteDataSource.refreshSession(
        refreshToken: refreshToken,
      );

      if (!sessionManager.isGenerationValid(startGen)) {
        throw const SecurityException('Stale session restoration ignored');
      }

      await sessionManager.setSession(
        learnerId: sessionModel.learner.id,
        accessToken: sessionModel.accessToken,
        refreshToken: sessionModel.refreshToken,
      );

      final session = sessionModel.toEntity(
        generation: sessionManager.sessionGeneration,
      );

      // Check offline lease validity upon restoration
      if (!validateOfflineAccess(session)) {
        return session.copyWith(status: SessionStatus.expired);
      }

      return session;
    } on AppException {
      // Do not delete local databases or drafts on network/restore failure;
      // require explicit re-authentication
      await sessionManager.invalidateSession();
      return null;
    } catch (_) {
      await sessionManager.invalidateSession();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final refreshToken = await sessionManager.getRefreshToken();
    try {
      if (refreshToken != null) {
        await remoteDataSource.logout(refreshToken: refreshToken);
      }
    } finally {
      await sessionManager.clearAll();
    }
  }

  @override
  Future<AuthSession> switchLearner({
    required String targetLearnerId,
    required String password,
  }) async {
    // 1. Immediately invalidate current session to block concurrent queries
    await sessionManager.invalidateSession();
    final switchGen = sessionManager.sessionGeneration;

    try {
      final sessionModel = await remoteDataSource.login(
        learnerId: targetLearnerId,
        password: password,
      );

      // 2. Ensure no interleaved operations changed session state
      if (!sessionManager.isGenerationValid(switchGen)) {
        throw const SecurityException('Conflicting account switch detected');
      }

      await sessionManager.setSession(
        learnerId: sessionModel.learner.id,
        accessToken: sessionModel.accessToken,
        refreshToken: sessionModel.refreshToken,
      );

      return sessionModel.toEntity(
        generation: sessionManager.sessionGeneration,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } catch (e) {
      throw ServerFailure('Account switch failed: $e');
    }
  }

  @override
  Future<AuthSession> refreshSession() async {
    final refreshToken = await sessionManager.getRefreshToken();
    if (refreshToken == null) {
      throw const ServerFailure('No refresh token available', statusCode: 401);
    }

    final startGen = sessionManager.sessionGeneration;
    try {
      final sessionModel = await remoteDataSource.refreshSession(
        refreshToken: refreshToken,
      );

      if (!sessionManager.isGenerationValid(startGen)) {
        throw const SecurityException('Stale token refresh ignored');
      }

      await sessionManager.setSession(
        learnerId: sessionModel.learner.id,
        accessToken: sessionModel.accessToken,
        refreshToken: sessionModel.refreshToken,
      );

      return sessionModel.toEntity(
        generation: sessionManager.sessionGeneration,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    }
  }

  @override
  bool validateOfflineAccess(AuthSession session) {
    final now = _clock();
    return !session.isOfflineLeaseExpired(now);
  }
}
