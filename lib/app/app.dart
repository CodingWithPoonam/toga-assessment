import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/lessons/presentation/bloc/lesson_bloc.dart';
import '../features/quiz/presentation/bloc/quiz_bloc.dart';
import '../features/quiz/presentation/bloc/quiz_event.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root application widget configuring routing, providers, and Material 3 theming
class TogaApp extends StatefulWidget {
  final GoRouter? routerOverride;

  const TogaApp({super.key, this.routerOverride});

  @override
  State<TogaApp> createState() => _TogaAppState();
}

class _TogaAppState extends State<TogaApp> {
  late final AuthBloc _authBloc;
  late final LessonBloc _lessonBloc;
  late final QuizBloc _quizBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>();
    _lessonBloc = getIt<LessonBloc>();
    _quizBloc = getIt<QuizBloc>();
    _router = widget.routerOverride ?? createAppRouter(_authBloc);

    // Trigger session restoration on app startup
    _authBloc.add(const AuthStarted());
  }

  @override
  void dispose() {
    _authBloc.close();
    _lessonBloc.close();
    _quizBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<LessonBloc>.value(value: _lessonBloc),
        BlocProvider<QuizBloc>.value(value: _quizBloc),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        bloc: _authBloc,
        listener: (context, authState) {
          if (authState is AuthUnauthenticated || authState is AuthSwitching) {
            _quizBloc.add(const ResetQuiz());
          }
        },
        child: MaterialApp.router(
          title: 'AIRMAN TOGA',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: _router,
        ),
      ),
    );
  }
}
