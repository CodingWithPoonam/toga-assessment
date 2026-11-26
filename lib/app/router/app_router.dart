import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';

/// Route path constants
abstract class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String lessons = '/lessons';
  static const String lessonDetail = '/lessons/:lessonId';
  static const String quiz = '/quiz/:lessonId';
  static const String submission = '/submission';

  static String lessonDetailPath(String lessonId) => '/lessons/$lessonId';
  static String quizPath(String lessonId) => '/quiz/$lessonId';
}

/// Listenable bridge syncing AuthBloc state changes with GoRouter
class AuthRouterNotifier extends ChangeNotifier {
  final AuthBloc _authBloc;
  late final StreamSubscription<AuthState> _subscription;

  AuthRouterNotifier(this._authBloc) {
    _subscription = _authBloc.stream.listen((_) => notifyListeners());
  }

  AuthState get authState => _authBloc.state;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Creates GoRouter configured with authentication guards
GoRouter createAppRouter(AuthBloc authBloc) {
  final authNotifier = AuthRouterNotifier(authBloc);

  return GoRouter(
    initialLocation: AppRoutes.lessons,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = authNotifier.authState;
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoggingIn = state.matchedLocation == AppRoutes.login;

      // Allow loading / initial states without premature redirection
      if (authState is AuthInitial ||
          authState is AuthLoading ||
          authState is AuthSwitching) {
        return null;
      }

      // Guard: Unauthenticated users attempting to access private routes
      if (!isAuthenticated && !isLoggingIn) {
        return AppRoutes.login;
      }

      // Guard: Authenticated users should not stay on the login page
      if (isAuthenticated && isLoggingIn) {
        return AppRoutes.lessons;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.lessons,
        name: 'lessons',
        builder: (context, state) => const LessonsCataloguePlaceholderScreen(),
        routes: [
          GoRoute(
            path: ':lessonId',
            name: 'lessonDetail',
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId'] ?? '';
              return _PlaceholderScreen(
                title: 'Lesson Detail',
                description: 'Detail view for lesson $lessonId (Phase 3)',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.quiz,
        name: 'quiz',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId'] ?? '';
          return _PlaceholderScreen(
            title: 'Quiz',
            description: 'Quiz workflow for lesson $lessonId (Phase 4)',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.submission,
        name: 'submission',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Submissions',
          description: 'Outbox submission sync status (Phase 5)',
        ),
      ),
    ],
  );
}

/// Interactive lessons catalogue placeholder displaying authenticated session info,
/// learner switching, and logout capabilities
class LessonsCataloguePlaceholderScreen extends StatelessWidget {
  const LessonsCataloguePlaceholderScreen({super.key});

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
          'Pending progress from the current session will remain securely isolated.',
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
      builder: (context, state) {
        final session = state is AuthAuthenticated ? state.session : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Lessons Catalogue'),
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
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              child: Text(
                                session?.learner.displayName.substring(0, 1) ??
                                    'L',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session?.learner.displayName ??
                                        'Authenticated Learner',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                  ),
                                  Text(
                                    session?.learner.email ?? '',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          'Session Generation: ${session?.sessionGeneration ?? 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'Offline Lease Valid Until: ${session?.offlineLeaseExpiresAt.toLocal().toString().substring(0, 16) ?? '24 Hours'}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.menu_book_outlined),
                    title: Text('Phase 2 Completed'),
                    subtitle: Text(
                      'Authentication, session management, and route guards are verified. '
                      'Lessons feature will be built in Phase 3.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String description;

  const _PlaceholderScreen({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
