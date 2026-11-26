import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/lessons/presentation/pages/lesson_detail_page.dart';
import '../../features/lessons/presentation/pages/lessons_page.dart';
import '../../features/quiz/presentation/pages/quiz_page.dart';

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
        builder: (context, state) => const LessonsPage(),
        routes: [
          GoRoute(
            path: ':lessonId',
            name: 'lessonDetail',
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId'] ?? '';
              return LessonDetailPage(lessonId: lessonId);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.quiz,
        name: 'quiz',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId'] ?? '';
          return QuizPage(lessonId: lessonId);
        },
      ),
      GoRoute(
        path: AppRoutes.submission,
        name: 'submission',
        builder: (context, state) => const _PlaceholderScreen(
          title: 'Submissions',
          description: 'Outbox submission sync status (Phase 3B)',
        ),
      ),
    ],
  );
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
