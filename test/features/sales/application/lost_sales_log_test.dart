import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/services/local_prefs.dart';
import 'package:tindascan/features/sales/application/lost_sales_log.dart';
import 'package:tindascan/shared/models/sale.dart';

Sale _sale(String receiptNo, int total) => Sale(
  id: 'id-$receiptNo',
  receiptNo: receiptNo,
  items: const [],
  totalCentavos: total,
  costTotalCentavos: 0,
  amountTenderedCentavos: total,
  changeCentavos: 0,
  cashierId: 'staff',
  cashierName: 'Staff',
  dayKey: '20261119',
  offline: true,
);

void main() {
  test(
    'records lost sales, survives a restart, and clears on dismiss',
    () async {
      final prefs = MemoryLocalPrefs();
      ProviderContainer container() {
        final c = ProviderContainer(
          overrides: [localPrefsProvider.overrideWithValue(prefs)],
        );
        addTearDown(c.dispose);
        return c;
      }

      final c = container();
      expect(await c.read(lostSalesProvider.future), isEmpty);

      await c
          .read(lostSalesProvider.notifier)
          .record(_sale('20261119-XAB12CD', 3200));
      await c
          .read(lostSalesProvider.notifier)
          .record(_sale('20261119-XEF34GH', 1600));
      final lost = await c.read(lostSalesProvider.future);
      expect(lost.map((s) => s.receiptNo), [
        '20261119-XAB12CD',
        '20261119-XEF34GH',
      ]);
      expect(lost.first.totalCentavos, 3200);

      // A new app session (new container) still sees them.
      final restarted = container();
      expect(await restarted.read(lostSalesProvider.future), hasLength(2));

      await restarted.read(lostSalesProvider.notifier).dismissAll();
      expect(await restarted.read(lostSalesProvider.future), isEmpty);
    },
  );
}
