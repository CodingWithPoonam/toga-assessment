import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

/// GoRouter configuration for application navigation
/// Routes are defined here and prepared for session guards in Phase 2
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const AppFoundationScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const _PlaceholderScreen(
        title: 'Authentication',
        description: 'Login screen placeholder (Phase 2)',
      ),
    ),
    GoRoute(
      path: AppRoutes.lessons,
      name: 'lessons',
      builder: (context, state) => const _PlaceholderScreen(
        title: 'Lessons',
        description: 'Lessons catalogue placeholder (Phase 3)',
      ),
      routes: [
        GoRoute(
          path: ':lessonId',
          name: 'lessonDetail',
          builder: (context, state) {
            final lessonId = state.pathParameters['lessonId'] ?? '';
            return _PlaceholderScreen(
              title: 'Lesson Detail',
              description: 'Detail view for lesson $lessonId',
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

/// Foundational home screen indicating initialized layers and readiness
class AppFoundationScreen extends StatelessWidget {
  const AppFoundationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AIRMAN TOGA')),
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
                    Text(
                      'Phase 1: Project Foundation',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Architecture setup complete. Core infrastructure, dependency injection, '
                      'networking, database, security, and router are initialized.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _ArchitectureLayerTile(
              title: 'State Management & UI',
              subtitle: 'flutter_bloc, Clean Architecture, Material 3',
              icon: Icons.layers_outlined,
            ),
            const _ArchitectureLayerTile(
              title: 'Dependency Injection',
              subtitle: 'GetIt modular registry with lifecycle separation',
              icon: Icons.alt_route_outlined,
            ),
            const _ArchitectureLayerTile(
              title: 'Networking Foundation',
              subtitle: 'Dio client with standardized error mapping & timeouts',
              icon: Icons.cloud_outlined,
            ),
            const _ArchitectureLayerTile(
              title: 'Local Persistence',
              subtitle: 'Drift SQLite boundary with migration support',
              icon: Icons.storage_outlined,
            ),
            const _ArchitectureLayerTile(
              title: 'Security Foundation',
              subtitle:
                  'AES-GCM-256 authenticated encryption & secure key storage',
              icon: Icons.security_outlined,
            ),
            const _ArchitectureLayerTile(
              title: 'Navigation',
              subtitle:
                  'GoRouter with typed path parameters & route guards ready',
              icon: Icons.navigation_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchitectureLayerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ArchitectureLayerTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
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
