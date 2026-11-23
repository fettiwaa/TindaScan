import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/services/local_prefs.dart';

/// Device-local appearance and feedback preferences.
@immutable
class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.system,
    this.haptics = true,
    this.scanSound = false,
  });

  final ThemeMode themeMode;

  /// Vibration feedback on add-to-cart, scans, sales and errors.
  final bool haptics;

  /// Soft click on a successful scan.
  final bool scanSound;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    bool? haptics,
    bool? scanSound,
  }) => AppPreferences(
    themeMode: themeMode ?? this.themeMode,
    haptics: haptics ?? this.haptics,
    scanSound: scanSound ?? this.scanSound,
  );
}

/// Loads and persists [AppPreferences] in [LocalPrefs].
class AppPreferencesController extends AsyncNotifier<AppPreferences> {
  static const String _themeKey = 'themeMode';
  static const String _hapticsKey = 'haptics';
  static const String _soundKey = 'scanSound';
  static const String _on = 'on';
  static const String _off = 'off';

  @override
  Future<AppPreferences> build() async {
    final prefs = ref.read(localPrefsProvider);
    final theme = await prefs.getString(_themeKey);
    final haptics = await prefs.getString(_hapticsKey);
    final sound = await prefs.getString(_soundKey);
    return AppPreferences(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => ThemeMode.system,
      ),
      haptics: haptics != _off,
      scanSound: sound == _on,
    );
  }

  Future<void> _save(AppPreferences next) async {
    state = AsyncData(next);
    final prefs = ref.read(localPrefsProvider);
    await prefs.setString(_themeKey, next.themeMode.name);
    await prefs.setString(_hapticsKey, next.haptics ? _on : _off);
    await prefs.setString(_soundKey, next.scanSound ? _on : _off);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _save((state.value ?? const AppPreferences()).copyWith(themeMode: mode));

  Future<void> setHaptics({required bool enabled}) =>
      _save((state.value ?? const AppPreferences()).copyWith(haptics: enabled));

  Future<void> setScanSound({required bool enabled}) => _save(
    (state.value ?? const AppPreferences()).copyWith(scanSound: enabled),
  );
}

final appPreferencesProvider =
    AsyncNotifierProvider<AppPreferencesController, AppPreferences>(
      AppPreferencesController.new,
    );

/// Haptic and sound feedback, honoring the user's toggles.
class AppFeedback {
  const AppFeedback(this._prefs);

  final AppPreferences _prefs;

  /// Add to cart, quantity change.
  void light() {
    if (_prefs.haptics) HapticFeedback.lightImpact();
  }

  /// Successful scan: light haptic plus the optional soft sound.
  void scanned() {
    light();
    if (_prefs.scanSound) SystemSound.play(SystemSoundType.click);
  }

  /// Sale completed.
  void success() {
    if (_prefs.haptics) HapticFeedback.mediumImpact();
  }

  /// Something failed (out of stock, unknown barcode, error).
  void error() {
    if (_prefs.haptics) HapticFeedback.vibrate();
  }
}

final feedbackProvider = Provider<AppFeedback>(
  (ref) => AppFeedback(
    ref.watch(appPreferencesProvider).value ?? const AppPreferences(),
  ),
);
