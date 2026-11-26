import 'dart:math';

/// Cryptographically secure RFC 4122 Version 4 UUID generator
class UuidGenerator {
  static final Random _random = Random.secure();

  /// Generates a lower-case RFC 4122 v4 UUID string
  static String v4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // Set version to 4 (bits 12-15 of time_hi_and_version to 0100)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant to RFC 4122 (bits 6-7 of clock_seq_hi_and_reserved to 10)
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
