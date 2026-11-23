import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:tindascan/core/errors/app_logger.dart';

/// Tiny key-value store for device-local preferences (language choice,
/// which low-stock notifications were already shown today).
///
/// Backed by one JSON file in the app-support directory, using
/// `path_provider` (already a dependency) instead of adding another plugin.
abstract interface class LocalPrefs {
  Future<String?> getString(String key);

  Future<void> setString(String key, String? value);

  Future<Map<String, String>> getMap(String key);

  Future<void> setMap(String key, Map<String, String> value);
}

/// Preference keys.
abstract final class PrefKeys {
  static const String locale = 'locale';
  static const String notifiedLowStock = 'notifiedLowStock';
  static const String lostOfflineSales = 'lostOfflineSales';
}

/// File-backed [LocalPrefs].
class FileLocalPrefs implements LocalPrefs {
  static const String _fileName = 'tindascan_prefs.json';

  Map<String, Object?>? _cache;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<Map<String, Object?>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final file = await _file();
      if (file.existsSync()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, Object?>) return _cache = decoded;
      }
    } on Object catch (error, stack) {
      AppLogger.error('LocalPrefs load', error, stack);
    }
    return _cache = <String, Object?>{};
  }

  Future<void> _save() async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode(_cache ?? const {}));
    } on Object catch (error, stack) {
      AppLogger.error('LocalPrefs save', error, stack);
    }
  }

  @override
  Future<String?> getString(String key) async {
    final value = (await _load())[key];
    return value is String ? value : null;
  }

  @override
  Future<void> setString(String key, String? value) async {
    final data = await _load();
    if (value == null) {
      data.remove(key);
    } else {
      data[key] = value;
    }
    await _save();
  }

  @override
  Future<Map<String, String>> getMap(String key) async {
    final value = (await _load())[key];
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        if (entry.value is String) entry.key.toString(): entry.value as String,
    };
  }

  @override
  Future<void> setMap(String key, Map<String, String> value) async {
    (await _load())[key] = value;
    await _save();
  }
}

/// In-memory [LocalPrefs] for tests.
class MemoryLocalPrefs implements LocalPrefs {
  final Map<String, Object?> _data = {};

  @override
  Future<String?> getString(String key) async => _data[key] as String?;

  @override
  Future<void> setString(String key, String? value) async =>
      value == null ? _data.remove(key) : _data[key] = value;

  @override
  Future<Map<String, String>> getMap(String key) async =>
      Map.of((_data[key] as Map<String, String>?) ?? const {});

  @override
  Future<void> setMap(String key, Map<String, String> value) async =>
      _data[key] = Map.of(value);
}

final localPrefsProvider = Provider<LocalPrefs>((ref) => FileLocalPrefs());
