import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/lesson_repository.dart';
import 'lesson_event.dart';
import 'lesson_state.dart';

/// Manages lesson catalogue retrieval, caching states, and offline reading
class LessonBloc extends Bloc<LessonEvent, LessonState> {
  final LessonRepository lessonRepository;

  LessonBloc({required this.lessonRepository}) : super(const LessonInitial()) {
    on<LoadLessons>(_onLoadLessons);
    on<LoadLessonDetail>(_onLoadLessonDetail);
  }

  Future<void> _onLoadLessons(
    LoadLessons event,
    Emitter<LessonState> emit,
  ) async {
    emit(const LessonLoading());
    try {
      final lessons = await lessonRepository.getLessons(
        forceRefresh: event.forceRefresh,
      );
      if (lessons.isEmpty) {
        emit(const LessonEmpty());
      } else {
        final hasCached = lessons.any((l) => l.isCached);
        emit(LessonSuccess(lessons, isOffline: hasCached));
      }
    } catch (e) {
      emit(LessonError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadLessonDetail(
    LoadLessonDetail event,
    Emitter<LessonState> emit,
  ) async {
    emit(const LessonLoading());
    try {
      final lesson = await lessonRepository.getLessonById(event.lessonId);
      emit(LessonDetailSuccess(lesson, isOffline: lesson.isCached));
    } catch (e) {
      emit(LessonError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
