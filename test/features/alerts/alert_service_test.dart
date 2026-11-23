import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/l10n/gen/app_localizations_en.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/services/local_prefs.dart';
import 'package:tindascan/features/alerts/application/alert_service.dart';
import 'package:tindascan/features/alerts/data/notification_service.dart';
import 'package:tindascan/shared/models/product.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/test_app.dart';

class _ThrowingNotifier implements AlertNotifier {
  @override
  Future<void> showLowStock(List<Product> products, AppLocalizations l10n) =>
      throw StateError('plugin missing');
}

void main() {
  var now = DateTime.utc(2026, 11, 21, 2);

  AlertService service(AlertNotifier notifier, {bool enabled = true}) =>
      AlertService(
        notifier: notifier,
        prefs: MemoryLocalPrefs(),
        l10n: AppLocalizationsEn.new,
        clock: () => now,
        enabled: () => enabled,
      );

  test('notifies low-stock products once per Manila day', () async {
    final notifier = FakeAlertNotifier();
    final alerts = service(notifier);
    final low = product(stock: 2);
    final fine = product(id: 'p2', stock: 20);

    expect(await alerts.evaluate([low, fine]), 1);
    expect(notifier.shown.single.single.id, 'p1');
    expect(await alerts.evaluate([low]), 0);

    now = now.add(const Duration(days: 1));
    expect(await alerts.evaluate([low]), 1);
  });

  test('skips staff (disabled) and archived products', () async {
    final notifier = FakeAlertNotifier();
    expect(
      await service(notifier, enabled: false).evaluate([product(stock: 0)]),
      0,
    );
    expect(
      await service(notifier).evaluate([product(stock: 0, active: false)]),
      0,
    );
    expect(notifier.shown, isEmpty);
  });

  test('never throws, even when the notification plugin fails', () async {
    expect(await service(_ThrowingNotifier()).evaluate([product(stock: 0)]), 0);
  });
}
