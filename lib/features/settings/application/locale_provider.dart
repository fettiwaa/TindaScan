import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/services/local_prefs.dart';

/// The in-app language choice; `null` follows the phone's language.
class LocaleController extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final code = await ref.read(localPrefsProvider).getString(PrefKeys.locale);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = AsyncData(locale);
    await ref
        .read(localPrefsProvider)
        .setString(PrefKeys.locale, locale?.languageCode);
  }
}

final localeProvider = AsyncNotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);
