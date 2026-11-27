import '../../../../core/network/api_exceptions.dart';
import '../models/learner_model.dart';
import '../models/session_model.dart';

/// Contract for remote authentication datasource aligning with AIRMAN candidate kit
abstract class AuthRemoteDataSource {
  Future<SessionModel> login({
    required String learnerId,
    required String password,
  });

  /// Official candidate kit endpoint: POST /auth/session with fixture_account
  Future<SessionModel> session({required String fixtureAccount});

  Future<SessionModel> refreshSession({required String refreshToken});

  Future<void> logout({String? refreshToken});
}

/// Authoritative synthetic fixtures from data/mock_accounts.json
abstract class SyntheticLearners {
  static const LearnerModel learnerA = LearnerModel(
    id: 'learner_a',
    displayName: 'Alex Mercer (Learner A)',
    email: 'alex.mercer@airman.internal',
    role: 'Learner',
  );

  static const LearnerModel learnerB = LearnerModel(
    id: 'learner_b',
    displayName: 'Blake Vance (Learner B)',
    email: 'blake.vance@airman.internal',
    role: 'Learner',
  );

  static const String validPassword = 'password123';

  // Authoritative tokens from data/mock_accounts.json
  static const String tokenAAccess1 = 'SYNTHETIC_A_ACCESS_1';
  static const String tokenARefresh1 = 'SYNTHETIC_A_REFRESH_1';
  static const String tokenAAccess2 = 'SYNTHETIC_A_ACCESS_2';
  static const String tokenARefresh2 = 'SYNTHETIC_A_REFRESH_2';

  static const String tokenBAccess1 = 'SYNTHETIC_B_ACCESS_1';
  static const String tokenBRefresh1 = 'SYNTHETIC_B_REFRESH_1';
  static const String tokenBAccess2 = 'SYNTHETIC_B_ACCESS_2';
  static const String tokenBRefresh2 = 'SYNTHETIC_B_REFRESH_2';
}

/// Injected mock authentication datasource matching the official TOGA Candidate Kit
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  final Duration networkLatency;
  final DateTime Function() _clock;

  // Active token state per account supporting rotation and revocation
  final Map<String, _AccountTokenState> _accounts = {};

  bool simulateRefreshFailure = false;

  MockAuthRemoteDataSource({
    this.networkLatency = const Duration(milliseconds: 60),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    resetAccounts();
  }

  void resetAccounts() {
    _accounts['learner_a'] = _AccountTokenState(
      learner: SyntheticLearners.learnerA,
      currentAccessToken: SyntheticLearners.tokenAAccess1,
      currentRefreshToken: SyntheticLearners.tokenARefresh1,
      rotatedAccessToken: SyntheticLearners.tokenAAccess2,
      rotatedRefreshToken: SyntheticLearners.tokenARefresh2,
    );
    _accounts['learner_b'] = _AccountTokenState(
      learner: SyntheticLearners.learnerB,
      currentAccessToken: SyntheticLearners.tokenBAccess1,
      currentRefreshToken: SyntheticLearners.tokenBRefresh1,
      rotatedAccessToken: SyntheticLearners.tokenBAccess2,
      rotatedRefreshToken: SyntheticLearners.tokenBRefresh2,
    );
  }

  String _normalizeLearnerId(String id) {
    if (id == 'learner-a' || id == 'learner_a') return 'learner_a';
    if (id == 'learner-b' || id == 'learner_b') return 'learner_b';
    return id;
  }

  @override
  Future<SessionModel> session({required String fixtureAccount}) async {
    final normalized = _normalizeLearnerId(fixtureAccount);
    return login(learnerId: normalized, password: SyntheticLearners.validPassword);
  }

  @override
  Future<SessionModel> login({
    required String learnerId,
    required String password,
  }) async {
    if (networkLatency > Duration.zero) {
      await Future<void>.delayed(networkLatency);
    }

    final normalized = _normalizeLearnerId(learnerId);
    final account = _accounts[normalized];
    if (account == null) {
      throw NotFoundException('Learner account not found');
    }

    if (password != SyntheticLearners.validPassword && password.isNotEmpty) {
      throw UnauthorizedException('Invalid credentials provided');
    }

    final now = _clock();
    return SessionModel(
      accessToken: account.currentAccessToken,
      refreshToken: account.currentRefreshToken,
      learner: account.learner,
      expiresAt: now.add(const Duration(hours: 1)),
      offlineLeaseExpiresAt: now.add(const Duration(hours: 24)),
    );
  }

  @override
  Future<SessionModel> refreshSession({required String refreshToken}) async {
    if (networkLatency > Duration.zero) {
      await Future<void>.delayed(networkLatency);
    }

    if (simulateRefreshFailure) {
      throw UnauthorizedException('Refresh denied by server policy');
    }

    // Locate matching account with this active refresh token
    for (final entry in _accounts.entries) {
      final account = entry.value;
      if (account.currentRefreshToken == refreshToken) {
        final now = _clock();
        // Rotate token pair and invalidate the old refresh token
        final newAccess = account.rotatedAccessToken;
        final newRefresh = account.rotatedRefreshToken;
        account.invalidatedRefreshTokens.add(refreshToken);
        account.currentAccessToken = newAccess;
        account.currentRefreshToken = newRefresh;

        return SessionModel(
          accessToken: newAccess,
          refreshToken: newRefresh,
          learner: account.learner,
          expiresAt: now.add(const Duration(hours: 1)),
          offlineLeaseExpiresAt: now.add(const Duration(hours: 24)),
        );
      } else if (account.invalidatedRefreshTokens.contains(refreshToken)) {
        throw UnauthorizedException('Revoked or previously rotated refresh token');
      }
    }

    throw UnauthorizedException('Invalid or expired refresh token');
  }

  @override
  Future<void> logout({String? refreshToken}) async {
    if (networkLatency > Duration.zero) {
      await Future<void>.delayed(networkLatency);
    }
  }
}

class _AccountTokenState {
  final LearnerModel learner;
  String currentAccessToken;
  String currentRefreshToken;
  final String rotatedAccessToken;
  final String rotatedRefreshToken;
  final Set<String> invalidatedRefreshTokens = {};

  _AccountTokenState({
    required this.learner,
    required this.currentAccessToken,
    required this.currentRefreshToken,
    required this.rotatedAccessToken,
    required this.rotatedRefreshToken,
  });
}
