import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class SecurityFailure extends Failure {
  const SecurityFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
