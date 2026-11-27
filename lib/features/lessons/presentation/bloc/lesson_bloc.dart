import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/lesson_repository.dart';
import 'lesson_event.dart';
import 'lesson_state.dart';

/// Manages lesson catalogue retrieval, caching states, and offline reading
class LessonBloc extends Bloc<LessonEvent, LessonState> {
  final LessonRepository lessonRepository;
  int _activeListGeneration = 0;
  int _activeDetailGeneration = 0;

  LessonBloc({required this.lessonRepository}) : super(const LessonInitial()) {
    on<LoadLessons>(_onLoadLessons);
    on<LoadLessonDetail>(_onLoadLessonDetail);
  }

  Future<void> _onLoadLessons(
    LoadLessons event,
    Emitter<LessonState> emit,
  ) async {
    final gen = ++_activeListGeneration;
    emit(const LessonLoading());
    try {
      final lessons = await lessonRepository.getLessons(
        forceRefresh: event.forceRefresh,
      );
      if (gen != _activeListGeneration || isClosed) return;
      if (lessons.isEmpty) {
        emit(const LessonEmpty());
      } else {
        final hasCached = lessons.any((l) => l.isCached);
        emit(LessonSuccess(lessons, isOffline: hasCached));
      }
    } catch (e) {
      if (gen != _activeListGeneration || isClosed) return;
      emit(LessonError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLoadLessonDetail(
    LoadLessonDetail event,
    Emitter<LessonState> emit,
  ) async {
    final gen = ++_activeDetailGeneration;
    emit(const LessonLoading());
    try {
      final lesson = await lessonRepository.getLessonById(event.lessonId);
      if (gen != _activeDetailGeneration || isClosed) return;
      emit(LessonDetailSuccess(lesson, isOffline: lesson.isCached));
    } catch (e) {
      if (gen != _activeDetailGeneration || isClosed) return;
      emit(LessonError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
