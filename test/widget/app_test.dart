import 'package:flutter_test/flutter_test.dart';
import 'package:toga_assessment/app/app.dart';
import 'package:toga_assessment/core/database/app_database.dart';
import 'package:toga_assessment/core/di/injection.dart';
import 'package:toga_assessment/core/network/network_config.dart';
import 'package:toga_assessment/core/security/secure_storage.dart';
import 'package:drift/native.dart';

class MockSecureStorage implements ISecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> deleteAll() async => _data.clear();

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;
}

void main() {
  setUp(() async {
    await configureDependencies(
      networkConfig: NetworkConfig.development(),
      secureStorageOverride: MockSecureStorage(),
      databaseOverride: AppDatabase(NativeDatabase.memory()),
    );
  });

  testWidgets(
    'TogaApp initializes and routes unauthenticated user to LoginPage',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TogaApp());
      await tester.pumpAndSettle();

      expect(find.text('AIRMAN TOGA Login'), findsOneWidget);
      expect(find.text('Synthetic Learner Access'), findsOneWidget);
      expect(find.text('Alex Mercer (Learner A)'), findsOneWidget);
      expect(find.text('Blake Vance (Learner B)'), findsOneWidget);
      expect(find.text('Authenticate & Enter'), findsOneWidget);
    },
  );
}
