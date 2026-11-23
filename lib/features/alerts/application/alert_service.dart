import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/errors/app_logger.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/services/local_prefs.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/features/alerts/data/notification_service.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/settings/application/locale_provider.dart';
import 'package:tindascan/shared/models/product.dart';

/// Low-stock alert rules (F-01 business layer).
///
/// Owns *whether* to notify: a product at or below its low-stock threshold
/// is announced at most once per product per Asia/Manila day. It does not
/// own stock values (it receives them) and never fails the caller: a sale
/// must not be undone because a notification could not be shown.
class AlertService {
  AlertService({
    required AlertNotifier notifier,
    required LocalPrefs prefs,
    required AppLocalizations Function() l10n,
    required DateTime Function() clock,
    required bool Function() enabled,
  }) : _notifier = notifier,
       _prefs = prefs,
       _l10n = l10n,
       _clock = clock,
       _enabled = enabled;

  final AlertNotifier _notifier;
  final LocalPrefs _prefs;
  final AppLocalizations Function() _l10n;
  final DateTime Function() _clock;
  final bool Function() _enabled;

  /// Shows notifications for [products] that are low on stock and were not
  /// announced yet today. Returns how many were shown; never throws.
  Future<int> evaluate(List<Product> products) async {
    if (!_enabled()) return 0;
    try {
      final today = ManilaTime.dayKey(_clock());
      final log = await _prefs.getMap(PrefKeys.notifiedLowStock);
      final due = [
        for (final p in products)
          if (p.isActive && p.isLowStock && log[p.id] != today) p,
      ];
      if (due.isEmpty) return 0;
      await _notifier.showLowStock(due, _l10n());
      // Keep only today's entries so the log never grows unbounded.
      await _prefs.setMap(PrefKeys.notifiedLowStock, {
        for (final entry in log.entries)
          if (entry.value == today) entry.key: entry.value,
        for (final product in due) product.id: today,
      });
      return due.length;
    } on Object catch (error, stack) {
      AppLogger.error('Low-stock notifications', error, stack);
      return 0;
    }
  }
}

/// Alerts go to the store owner (staff phones do not get them).
final alertServiceProvider = Provider<AlertService>(
  (ref) => AlertService(
    notifier: ref.watch(alertNotifierProvider),
    prefs: ref.watch(localPrefsProvider),
    clock: ref.watch(clockProvider),
    enabled: () => ref.read(currentUserProvider)?.isOwner ?? false,
    l10n: () {
      final locale =
          ref.read(localeProvider).value ?? PlatformDispatcher.instance.locale;
      return lookupAppLocalizations(
        AppLocalizations.delegate.isSupported(locale)
            ? Locale(locale.languageCode)
            : const Locale('en'),
      );
    },
  ),
);
