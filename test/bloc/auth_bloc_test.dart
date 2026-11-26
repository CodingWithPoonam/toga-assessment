import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toga_assessment/core/errors/failures.dart';
import 'package:toga_assessment/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:toga_assessment/features/auth/domain/entities/auth_session.dart';
import 'package:toga_assessment/features/auth/domain/repositories/auth_repository.dart';
import 'package:toga_assessment/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:toga_assessment/features/auth/presentation/bloc/auth_event.dart';
import 'package:toga_assessment/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  final sampleSessionA = AuthSession(
    learnerId: SyntheticLearners.learnerA.id,
    learner: SyntheticLearners.learnerA,
    expiresAt: DateTime(2026, 11, 26, 13, 0),
    offlineLeaseExpiresAt: DateTime(2026, 11, 27, 12, 0),
    sessionGeneration: 1,
  );

  final sampleSessionB = AuthSession(
    learnerId: SyntheticLearners.learnerB.id,
    learner: SyntheticLearners.learnerB,
    expiresAt: DateTime(2026, 11, 26, 13, 0),
    offlineLeaseExpiresAt: DateTime(2026, 11, 27, 12, 0),
    sessionGeneration: 2,
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'AuthStarted emits [AuthLoading, AuthAuthenticated] when session restored successfully',
      build: () {
        when(
          () => mockAuthRepository.restoreSession(),
        ).thenAnswer((_) async => sampleSessionA);
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(session: sampleSessionA),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthStarted emits [AuthLoading, AuthUnauthenticated] when no session exists',
      build: () {
        when(
          () => mockAuthRepository.restoreSession(),
        ).thenAnswer((_) async => null);
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthStarted()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'LoginRequested emits [AuthLoading, AuthAuthenticated] on success',
      build: () {
        when(
          () => mockAuthRepository.login(
            learnerId: SyntheticLearners.learnerA.id,
            password: SyntheticLearners.validPassword,
          ),
        ).thenAnswer((_) async => sampleSessionA);
        return authBloc;
      },
      act: (bloc) => bloc.add(
        LoginRequested(
          learnerId: SyntheticLearners.learnerA.id,
          password: SyntheticLearners.validPassword,
        ),
      ),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(session: sampleSessionA),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'LoginRequested emits [AuthLoading, AuthFailure] on invalid credentials',
      build: () {
        when(
          () => mockAuthRepository.login(
            learnerId: SyntheticLearners.learnerA.id,
            password: 'wrong',
          ),
        ).thenThrow(const ServerFailure('Invalid credentials provided'));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        LoginRequested(
          learnerId: SyntheticLearners.learnerA.id,
          password: 'wrong',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthFailure(message: 'Invalid credentials provided'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'LogoutRequested emits [AuthLoading, AuthUnauthenticated]',
      build: () {
        when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'SwitchLearnerRequested emits [AuthSwitching, AuthAuthenticated] on success',
      build: () {
        when(
          () => mockAuthRepository.switchLearner(
            targetLearnerId: SyntheticLearners.learnerB.id,
            password: SyntheticLearners.validPassword,
          ),
        ).thenAnswer((_) async => sampleSessionB);
        return authBloc;
      },
      act: (bloc) => bloc.add(
        SwitchLearnerRequested(
          targetLearnerId: SyntheticLearners.learnerB.id,
          password: SyntheticLearners.validPassword,
        ),
      ),
      expect: () => [
        AuthSwitching(targetLearnerId: SyntheticLearners.learnerB.id),
        AuthAuthenticated(session: sampleSessionB),
      ],
    );
  });
}
