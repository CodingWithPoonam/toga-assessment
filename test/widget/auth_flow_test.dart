import 'package:flutter_test/flutter_test.dart';
import 'package:toga_assessment/app/app.dart';
import 'package:toga_assessment/core/database/app_database.dart';
import 'package:toga_assessment/core/di/injection.dart';
import 'package:toga_assessment/core/network/network_config.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';
import 'package:toga_assessment/core/security/session_manager.dart';
import 'package:toga_assessment/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:toga_assessment/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:toga_assessment/features/auth/domain/repositories/auth_repository.dart';
import 'package:drift/native.dart';

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
  late ISecureStorage secureStorage;
  late ISessionManager sessionManager;
  late AuthRemoteDataSource remoteDataSource;
  late AuthRepository authRepository;

  setUp(() async {
    secureStorage = InMemorySecureStorage();
    sessionManager = SessionManager(secureStorage: secureStorage);
    remoteDataSource = MockAuthRemoteDataSource(networkLatency: Duration.zero);
    authRepository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      sessionManager: sessionManager,
    );

    await configureDependencies(
      networkConfig: NetworkConfig.development(),
      secureStorageOverride: secureStorage,
      sessionManagerOverride: sessionManager,
      remoteDataSourceOverride: remoteDataSource,
      authRepositoryOverride: authRepository,
      databaseOverride: AppDatabase(NativeDatabase.memory()),
    );
  });

  group('Authentication Flow and GoRouter Guards', () {
    testWidgets('9. Unauthenticated private route redirects to /login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const TogaApp());
      await tester.pumpAndSettle();

      // Because user starts unauthenticated, GoRouter redirects from /lessons to /login
      expect(find.text('AIRMAN TOGA Login'), findsOneWidget);
      expect(find.text('Synthetic Learner Access'), findsOneWidget);
      expect(find.text('Alex Mercer (Learner A)'), findsOneWidget);
      expect(find.text('Blake Vance (Learner B)'), findsOneWidget);
    });

    testWidgets(
      '10. Authenticated user accesses lessons and can switch accounts or logout',
      (WidgetTester tester) async {
        await tester.pumpWidget(const TogaApp());
        await tester.pumpAndSettle();

        // Ensure button is visible before tapping
        await tester.ensureVisible(find.text('Authenticate & Enter'));
        await tester.pumpAndSettle();

        // Tap login with Learner A
        await tester.tap(find.text('Authenticate & Enter'));
        await tester.pumpAndSettle();

        // Authenticated route /lessons displayed
        expect(find.text('Lessons Catalogue'), findsOneWidget);
        expect(find.text('Alex Mercer (Learner A)'), findsOneWidget);
        expect(find.text('Phase 2 Completed'), findsOneWidget);

        // Verify switch account dialog
        await tester.tap(find.byTooltip('Switch Learner'));
        await tester.pumpAndSettle();

        expect(find.text('Switch Learner Account'), findsOneWidget);
        await tester.tap(find.text('Confirm Switch'));
        await tester.pumpAndSettle();

        // Now authenticated as Learner B
        expect(find.text('Blake Vance (Learner B)'), findsOneWidget);

        // Verify logout
        await tester.tap(find.byTooltip('Logout'));
        await tester.pumpAndSettle();

        expect(find.text('Confirm Logout'), findsOneWidget);
        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        // Redirected back to login
        expect(find.text('AIRMAN TOGA Login'), findsOneWidget);
      },
    );
  });
}
