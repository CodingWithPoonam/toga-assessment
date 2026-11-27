import 'dart:io';

/// Abstract adapter for reading and deleting plaintext legacy private data
abstract class ILegacyMigrationSource {
  Future<String?> readRawLegacyData();
  Future<void> deleteLegacyData();
}

/// File-backed legacy migration adapter for test fixtures or real storage files
class FileLegacyMigrationSource implements ILegacyMigrationSource {
  final File file;
  FileLegacyMigrationSource(this.file);

  @override
  Future<String?> readRawLegacyData() async {
    if (!file.existsSync()) return null;
    try {
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteLegacyData() async {
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

/// In-memory legacy migration adapter for fast, isolated testing
class InMemoryLegacyMigrationSource implements ILegacyMigrationSource {
  String? _data;
  InMemoryLegacyMigrationSource([this._data]);

  void setData(String? data) => _data = data;
  String? get currentData => _data;

  @override
  Future<String?> readRawLegacyData() async => _data;

  @override
  Future<void> deleteLegacyData() async {
    _data = null;
  }
}
