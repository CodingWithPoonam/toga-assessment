import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Manages authentication workflow and session transitions
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  bool _isSwitching = false;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<SwitchLearnerRequested>(_onSwitchLearnerRequested);
    on<SessionExpired>(_onSessionExpired);
    on<OfflineSessionValidationRequested>(_onOfflineSessionValidationRequested);
  }

  Future<void> _onAuthStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final session = await authRepository.restoreSession();
      if (session != null) {
        if (session.status == SessionStatus.expired) {
          emit(
            const AuthUnauthenticated(
              message: 'Offline access lease has expired. Please log in again.',
            ),
          );
        } else {
          emit(AuthAuthenticated(session: session));
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final session = await authRepository.login(
        learnerId: event.learnerId,
        password: event.password,
      );
      emit(AuthAuthenticated(session: session));
    } on Failure catch (e) {
      emit(AuthFailure(message: e.message));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.logout();
    } finally {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSwitchLearnerRequested(
    SwitchLearnerRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_isSwitching) return;
    _isSwitching = true;

    emit(AuthSwitching(targetLearnerId: event.targetLearnerId));
    try {
      final session = await authRepository.switchLearner(
        targetLearnerId: event.targetLearnerId,
        password: event.password,
      );
      emit(AuthAuthenticated(session: session));
    } on Failure catch (e) {
      emit(AuthFailure(message: e.message));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    } finally {
      _isSwitching = false;
    }
  }

  void _onSessionExpired(SessionExpired event, Emitter<AuthState> emit) {
    emit(
      AuthUnauthenticated(
        message: event.reason ?? 'Session has expired. Please log in again.',
      ),
    );
  }

  void _onOfflineSessionValidationRequested(
    OfflineSessionValidationRequested event,
    Emitter<AuthState> emit,
  ) {
    if (state is AuthAuthenticated) {
      final currentSession = (state as AuthAuthenticated).session;
      final isValid = authRepository.validateOfflineAccess(currentSession);
      if (!isValid) {
        emit(
          const AuthUnauthenticated(
            message: 'Offline session lease expired (24-hour limit reached)',
          ),
        );
      }
    }
  }
}
