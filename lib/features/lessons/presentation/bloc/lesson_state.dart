import 'package:equatable/equatable.dart';
import '../../domain/entities/lesson.dart';

abstract class LessonState extends Equatable {
  const LessonState();

  @override
  List<Object?> get props => [];
}

class LessonInitial extends LessonState {
  const LessonInitial();
}

class LessonLoading extends LessonState {
  const LessonLoading();
}

class LessonSuccess extends LessonState {
  final List<Lesson> lessons;
  final bool isOffline;

  const LessonSuccess(this.lessons, {this.isOffline = false});

  @override
  List<Object?> get props => [lessons, isOffline];
}

class LessonDetailSuccess extends LessonState {
  final Lesson lesson;
  final bool isOffline;

  const LessonDetailSuccess(this.lesson, {this.isOffline = false});

  @override
  List<Object?> get props => [lesson, isOffline];
}

class LessonEmpty extends LessonState {
  const LessonEmpty();
}

class LessonError extends LessonState {
  final String message;

  const LessonError(this.message);

  @override
  List<Object?> get props => [message];
}
