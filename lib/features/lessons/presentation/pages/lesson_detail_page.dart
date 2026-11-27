import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toga_assessment/app/router/app_router.dart';
import '../bloc/lesson_bloc.dart';
import '../bloc/lesson_event.dart';
import '../bloc/lesson_state.dart';

/// Lesson details and study reading page with offline caching support
class LessonDetailPage extends StatefulWidget {
  final String lessonId;

  const LessonDetailPage({super.key, required this.lessonId});

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<LessonBloc>().add(LoadLessonDetail(widget.lessonId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Detail')),
      body: BlocBuilder<LessonBloc, LessonState>(
        builder: (context, state) {
          if (state is LessonLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LessonError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            );
          }

          if (state is LessonDetailSuccess) {
            final lesson = state.lesson;

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      Text(
                        lesson.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(lesson.revisionId),
                        backgroundColor: colorScheme.secondaryContainer,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        lesson.isCached
                            ? Icons.offline_pin
                            : Icons.cloud_outlined,
                        size: 18,
                        color: lesson.isCached
                            ? Colors.green
                            : colorScheme.outline,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        lesson.isCached
                            ? 'Cached on device'
                            : 'Loaded from server',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Lesson Body Content
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        lesson.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      context.push(AppRoutes.quizPath(lesson.id));
                    },
                    icon: const Icon(Icons.quiz_outlined),
                    label: const Text('Take Lesson Quiz'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
