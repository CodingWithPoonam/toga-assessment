import '../../domain/entities/learner.dart';

/// Data model representing a learner with JSON serialization
class LearnerModel extends Learner {
  const LearnerModel({
    required super.id,
    required super.displayName,
    required super.email,
    super.role = 'Learner',
  });

  factory LearnerModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final displayName =
        json['displayName'] as String? ?? json['name'] as String?;
    final email = json['email'] as String?;
    final role = json['role'] as String? ?? 'Learner';

    if (id == null || id.isEmpty) {
      throw const FormatException('Missing or invalid learner ID in response');
    }
    if (displayName == null || displayName.isEmpty) {
      throw const FormatException(
        'Missing or invalid learner displayName in response',
      );
    }
    if (email == null || email.isEmpty) {
      throw const FormatException(
        'Missing or invalid learner email in response',
      );
    }

    return LearnerModel(
      id: id,
      displayName: displayName,
      email: email,
      role: role,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'email': email,
    'role': role,
  };

  factory LearnerModel.fromEntity(Learner entity) {
    return LearnerModel(
      id: entity.id,
      displayName: entity.displayName,
      email: entity.email,
      role: entity.role,
    );
  }
}
