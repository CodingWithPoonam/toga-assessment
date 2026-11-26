import '../../../../core/network/api_exceptions.dart';
import '../models/learner_model.dart';
import '../models/session_model.dart';

/// Contract for remote authentication datasource
abstract class AuthRemoteDataSource {
  Future<SessionModel> login({
    required String learnerId,
    required String password,
  });

  Future<SessionModel> refreshSession({required String refreshToken});

  Future<void> logout({String? refreshToken});
}

/// Explicit synthetic fixtures for the assessment
abstract class SyntheticLearners {
  static const LearnerModel learnerA = LearnerModel(
    id: 'learner-a',
    displayName: 'Alex Mercer (Learner A)',
    email: 'alex.mercer@airman.internal',
    role: 'Learner',
  );

  static const LearnerModel learnerB = LearnerModel(
    id: 'learner-b',
    displayName: 'Blake Vance (Learner B)',
    email: 'blake.vance@airman.internal',
    role: 'Learner',
  );

  static const String validPassword = 'password123';
}

/// Isolated mock authentication datasource utilizing synthetic fixtures
/// Replaceable with Dio-based implementation once remote backend is provided
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  final Duration networkLatency;
  final DateTime Function() _clock;

  MockAuthRemoteDataSource({
    this.networkLatency = const Duration(milliseconds: 100),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  @override
  Future<SessionModel> login({
    required String learnerId,
    required String password,
  }) async {
    if (networkLatency > Duration.zero) {
      await Future<void>.delayed(networkLatency);
    }

    if (password != SyntheticLearners.validPassword) {
      throw UnauthorizedException('Invalid credentials provided');
    }

    final LearnerModel learner;
    if (learnerId == SyntheticLearners.learnerA.id) {
      learner = SyntheticLearners.learnerA;
    } else if (learnerId == SyntheticLearners.learnerB.id) {
      learner = SyntheticLearners.learnerB;
    } else {
      throw NotFoundException('Learner account not found');
    }

    final now = _clock();
    return SessionModel(
      accessToken:
          'synthetic_access_token_${learner.id}_${now.millisecondsSinceEpoch}',
      refreshToken:
          'synthetic_refresh_token_${learner.id}_${now.millisecondsSinceEpoch}',
      learner: learner,
      expiresAt: now.add(const Duration(hours: 1)),
      offlineLeaseExpiresAt: now.add(const Duration(hours: 24)),
    );
  }

  @override
  Future<SessionModel> refreshSession({required String refreshToken}) async {
    if (networkLatency > Duration.zero) {
      await Future<void>.delayed(networkLatency);
    }

    final LearnerModel learner;
    if (refreshToken.contains('learner-a')) {
      learner = SyntheticLearners.learnerA;
    } else if (refreshToken.contains('learner-b')) {
      learner = SyntheticLearners.learnerB;
    } else {
      throw UnauthorizedException('Invalid or expired refresh token');
    }

    final now = _clock();
    return SessionModel(
      accessToken:
          'synthetic_access_token_${learner.id}_${now.millisecondsSinceEpoch}',
      refreshToken: refreshToken,
      learner: learner,
      expiresAt: now.add(const Duration(hours: 1)),
      offlineLeaseExpiresAt: now.add(const Duration(hours: 24)),
    );
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    if (networkLatency > Duration.zero) {
      await Future<void>.delayed(networkLatency);
    }
  }
}
