import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:toga_assessment/app/app.dart';
import 'package:toga_assessment/core/database/app_database.dart';
import 'package:toga_assessment/core/di/injection.dart';
import 'package:toga_assessment/core/network/network_config.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';
import 'package:toga_assessment/core/security/session_manager.dart';
import 'package:toga_assessment/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:toga_assessment/features/auth/data/repositories/auth_repository_impl.dart';

class InMemorySecureStorage implements ISecureStorage {
  final Map<String, String> _map = {};

  @override
  Future<bool> containsKey(String key) async => _map.containsKey(key);

  @override
  Future<void> delete(String key) async => _map.remove(key);

  @override
  Future<void> deleteAll() async => _map.clear();

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;
}

void main() {
  late AppDatabase database;
  late ISecureStorage secureStorage;
  late ISessionManager sessionManager;
  late AuthRemoteDataSource authRemoteDataSource;
  late AuthRepositoryImpl authRepository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    secureStorage = InMemorySecureStorage();
    sessionManager = SessionManager(secureStorage: secureStorage);
    authRemoteDataSource = MockAuthRemoteDataSource(
      networkLatency: Duration.zero,
    );
    authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
      sessionManager: sessionManager,
    );

    await configureDependencies(
      networkConfig: NetworkConfig.development(),
      secureStorageOverride: secureStorage,
      sessionManagerOverride: sessionManager,
      remoteDataSourceOverride: authRemoteDataSource,
      authRepositoryOverride: authRepository,
      databaseOverride: database,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('Lessons and Quiz Flow Widget Tests', () {
    testWidgets(
      'Logs in, views lesson catalogue, views lesson detail, and starts quiz',
      (WidgetTester tester) async {
        await tester.pumpWidget(const TogaApp());
        await tester.pumpAndSettle();

        // 1. Log in as Learner A
        await tester.ensureVisible(find.text('Authenticate & Enter'));
        await tester.tap(find.text('Authenticate & Enter'));
        await tester.pumpAndSettle();

        // 2. Lesson Catalogue displayed
        expect(find.text('Lesson Catalogue'), findsOneWidget);
        expect(find.text('Aerodynamics & Flight Principles'), findsOneWidget);
        expect(
          find.text('Aircraft Instruments & Navigation Systems'),
          findsOneWidget,
        );

        // 3. Tap on first lesson to view detail
        await tester.tap(find.text('Aerodynamics & Flight Principles'));
        await tester.pumpAndSettle();

        expect(find.text('Lesson Detail'), findsOneWidget);

        // Scroll to and tap Take Lesson Quiz
        await tester.scrollUntilVisible(
          find.text('Take Lesson Quiz'),
          100.0,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(find.text('Take Lesson Quiz'), findsOneWidget);

        // 4. Tap Take Lesson Quiz
        await tester.tap(find.text('Take Lesson Quiz'));
        await tester.pumpAndSettle();

        // 5. Quiz screen loaded
        expect(find.text('Lesson Quiz'), findsOneWidget);
        expect(find.text('Question 1 of 5'), findsOneWidget);
        expect(
          find.text(
            'What primary aerodynamic force overcomes an aircraft\'s weight during steady flight?',
          ),
          findsOneWidget,
        );

        // 6. Select option Lift (opt_1c)
        expect(find.text('Lift'), findsOneWidget);
        await tester.tap(find.text('Lift'));
        await tester.pumpAndSettle();

        // 7. Navigate to Next Question
        expect(find.text('Next'), findsOneWidget);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // 8. Question 2 of 5
        expect(find.text('Question 2 of 5'), findsOneWidget);
        expect(find.text('Answered: 1/5'), findsOneWidget);
      },
    );
  });
}
