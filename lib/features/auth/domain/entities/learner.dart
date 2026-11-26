import 'package:equatable/equatable.dart';

/// Verified learner entity containing non-sensitive display information
class Learner extends Equatable {
  final String id;
  final String displayName;
  final String email;
  final String role;

  const Learner({
    required this.id,
    required this.displayName,
    required this.email,
    this.role = 'Learner',
  });

  @override
  List<Object?> get props => [id, displayName, email, role];

  @override
  String toString() =>
      'Learner(id: $id, displayName: $displayName, role: $role)';
}
