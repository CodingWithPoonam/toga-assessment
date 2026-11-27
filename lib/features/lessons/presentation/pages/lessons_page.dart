import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toga_assessment/app/router/app_router.dart';
import 'package:toga_assessment/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:toga_assessment/features/auth/domain/entities/auth_session.dart';
import 'package:toga_assessment/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:toga_assessment/features/auth/presentation/bloc/auth_event.dart';
import 'package:toga_assessment/features/auth/presentation/bloc/auth_state.dart';
import '../bloc/lesson_bloc.dart';
import '../bloc/lesson_event.dart';
import '../bloc/lesson_state.dart';

/// Material 3 lesson catalogue listing available flight lessons
class LessonsPage extends StatefulWidget {
  const LessonsPage({super.key});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  @override
  void initState() {
    super.initState();
    context.read<LessonBloc>().add(const LoadLessons());
  }

  void _showAccountSwitchDialog(BuildContext context, AuthSession? session) {
    final currentLearnerId = session?.learnerId;
    final targetLearner = currentLearnerId == SyntheticLearners.learnerA.id
        ? SyntheticLearners.learnerB
        : SyntheticLearners.learnerA;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Switch Learner Account'),
        content: Text(
          'Switch active session to ${targetLearner.displayName}? '
          'Your quiz drafts and progress remain isolated per account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(
                SwitchLearnerRequested(
                  targetLearnerId: targetLearner.id,
                  password: SyntheticLearners.validPassword,
                ),
              );
            },
            child: const Text('Confirm Switch'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
          'Logging out will terminate the active session and remove tokens from memory. '
          'Protected drafts remain safely stored for your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final session = authState is AuthAuthenticated
            ? authState.session
            : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Lesson Catalogue'),
            actions: [
              IconButton(
                icon: const Icon(Icons.swap_horiz_outlined),
                tooltip: 'Switch Learner',
                onPressed: () => _showAccountSwitchDialog(context, session),
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                tooltip: 'Logout',
                onPressed: () => _showLogoutConfirmation(context),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<LessonBloc>().add(
                const LoadLessons(forceRefresh: true),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Learner Session Header
                Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12.0,
                      runSpacing: 8.0,
                      children: [
                        CircleAvatar(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          child: Text(
                            session?.learner.displayName.substring(0, 1) ?? 'L',
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              session?.learner.displayName ?? 'Learner',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              session?.learner.email ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Chip(
                          avatar: const Icon(Icons.shield_outlined, size: 16),
                          label: Text('Gen ${session?.sessionGeneration ?? 1}'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Available Lessons',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                BlocBuilder<LessonBloc, LessonState>(
                  builder: (context, lessonState) {
                    if (lessonState is LessonLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (lessonState is LessonError) {
                      return Card(
                        color: colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            lessonState.message,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      );
                    }

                    if (lessonState is LessonEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text('No lessons currently available.'),
                          ),
                        ),
                      );
                    }

                    if (lessonState is LessonSuccess) {
                      return Column(
                        children: lessonState.lessons.map((lesson) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                context.push(
                                  AppRoutes.lessonDetailPath(lesson.id),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children: [
                                        Text(
                                          lesson.title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Chip(
                                          label: Text(lesson.revisionId),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      lesson.summary,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6.0,
                                          runSpacing: 2.0,
                                          children: [
                                            Icon(
                                              lesson.isCached
                                                  ? Icons.offline_pin
                                                  : Icons.cloud_download_outlined,
                                              size: 16,
                                              color: lesson.isCached
                                                  ? colorScheme.primary
                                                  : colorScheme.outline,
                                            ),
                                            Text(
                                              lesson.isCached
                                                  ? 'Cached for offline'
                                                  : 'Available online',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: lesson.isCached
                                                        ? colorScheme.primary
                                                        : colorScheme.outline,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Read Lesson >',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
