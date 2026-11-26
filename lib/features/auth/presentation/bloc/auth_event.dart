import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class LoginRequested extends AuthEvent {
  final String learnerId;
  final String password;

  const LoginRequested({required this.learnerId, required this.password});

  @override
  List<Object?> get props => [learnerId, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class SwitchLearnerRequested extends AuthEvent {
  final String targetLearnerId;
  final String password;

  const SwitchLearnerRequested({
    required this.targetLearnerId,
    required this.password,
  });

  @override
  List<Object?> get props => [targetLearnerId, password];
}

class SessionExpired extends AuthEvent {
  final String? reason;

  const SessionExpired({this.reason});

  @override
  List<Object?> get props => [reason];
}

class OfflineSessionValidationRequested extends AuthEvent {
  const OfflineSessionValidationRequested();
}
