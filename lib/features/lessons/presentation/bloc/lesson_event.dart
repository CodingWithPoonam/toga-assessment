import 'package:equatable/equatable.dart';

abstract class LessonEvent extends Equatable {
  const LessonEvent();

  @override
  List<Object?> get props => [];
}

class LoadLessons extends LessonEvent {
  final bool forceRefresh;

  const LoadLessons({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadLessonDetail extends LessonEvent {
  final String lessonId;

  const LoadLessonDetail(this.lessonId);

  @override
  List<Object?> get props => [lessonId];
}
