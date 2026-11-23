import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/errors/app_logger.dart';
import 'package:tindascan/core/services/local_prefs.dart';
import 'package:tindascan/shared/models/sale.dart';

/// An offline sale the server rejected when it synced. The cash was taken
/// but the record is gone, so the cashier has to re-enter it.
@immutable
class LostSale {
  const LostSale({required this.receiptNo, required this.totalCentavos});

  final String receiptNo;
  final int totalCentavos;
}

/// Remembers lost offline sales on this phone (in [LocalPrefs]) until the
/// cashier dismisses the warning on the Sell screen.
class LostSalesLog extends AsyncNotifier<List<LostSale>> {
  static const String _key = PrefKeys.lostOfflineSales;

  LocalPrefs get _prefs => ref.read(localPrefsProvider);

  @override
  Future<List<LostSale>> build() async {
    final map = await _prefs.getMap(_key);
    return [
      for (final entry in map.entries)
        LostSale(
          receiptNo: entry.key,
          totalCentavos: int.tryParse(entry.value) ?? 0,
        ),
    ];
  }

  Future<void> record(Sale sale) async {
    try {
      final map = await _prefs.getMap(_key);
      await _prefs.setMap(_key, {
        ...map,
        sale.receiptNo: '${sale.totalCentavos}',
      });
      ref.invalidateSelf();
    } on Object catch (error, stack) {
      AppLogger.error('Lost sale log', error, stack);
    }
  }

  Future<void> dismissAll() async {
    await _prefs.setMap(_key, const {});
    ref.invalidateSelf();
  }
}

final lostSalesProvider = AsyncNotifierProvider<LostSalesLog, List<LostSale>>(
  LostSalesLog.new,
);
