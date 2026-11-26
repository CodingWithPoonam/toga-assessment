import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core infrastructure and dependencies
  await configureDependencies();

  runApp(const TogaApp());
}
