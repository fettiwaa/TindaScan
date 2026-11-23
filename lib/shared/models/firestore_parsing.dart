import 'package:cloud_firestore/cloud_firestore.dart';

/// Null-safe readers for loosely typed Firestore maps.
///
/// Firestore returns `Map<String, dynamic>`; these helpers confine the
/// dynamic access to one file and fall back to safe defaults.
extension FirestoreMapReader on Map<String, Object?> {
  String readString(String key, [String fallback = '']) {
    final value = this[key];
    return value is String ? value : fallback;
  }

  String? readStringOrNull(String key) {
    final value = this[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  int readInt(String key, [int fallback = 0]) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  bool readBool(String key, {bool fallback = false}) {
    final value = this[key];
    return value is bool ? value : fallback;
  }

  /// Reads a Firestore [Timestamp] (or a pending server timestamp, which is
  /// `null` locally until the write is acknowledged).
  DateTime? readDateTime(String key) {
    final value = this[key];
    // Always UTC; display code converts to Manila time explicitly.
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    return null;
  }

  Map<String, Object?> readMap(String key) {
    final value = this[key];
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v as Object?));
    }
    return const {};
  }

  List<Map<String, Object?>> readMapList(String key) {
    final value = this[key];
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map)
          item.map((k, v) => MapEntry(k.toString(), v as Object?)),
    ];
  }
}
