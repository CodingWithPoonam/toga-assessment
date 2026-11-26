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

  testWidgets('TogaApp renders AppFoundationScreen with architecture status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TogaApp());
    await tester.pumpAndSettle();

    expect(find.text('AIRMAN TOGA'), findsOneWidget);
    expect(find.text('Phase 1: Project Foundation'), findsOneWidget);
    expect(find.text('State Management & UI'), findsOneWidget);
    expect(find.text('Dependency Injection'), findsOneWidget);
    expect(find.text('Networking Foundation'), findsOneWidget);

    // Scroll to verify lower items
    await tester.scrollUntilVisible(find.text('Navigation'), 100);
    expect(find.text('Navigation'), findsOneWidget);
  });
}
