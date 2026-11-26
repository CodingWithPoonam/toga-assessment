import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root application widget configuring routing and Material 3 theming
class TogaApp extends StatelessWidget {
  const TogaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AIRMAN TOGA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
