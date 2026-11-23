import 'package:flutter/foundation.dart';

import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/shared/models/firestore_parsing.dart';

/// Per-product totals for one day (used for best-sellers).
@immutable
class ProductDayStat {
  const ProductDayStat({
    required this.productId,
    required this.name,
    required this.qty,
    required this.salesCentavos,
  });

  final String productId;
  final String name;
  final int qty;
  final int salesCentavos;

  @override
  bool operator ==(Object other) =>
      other is ProductDayStat &&
      other.productId == productId &&
      other.name == name &&
      other.qty == qty &&
      other.salesCentavos == salesCentavos;

  @override
  int get hashCode => Object.hash(productId, name, qty, salesCentavos);
}

/// Aggregates for one Manila day (`daily_stats/{yyyyMMdd}`), maintained with
/// `FieldValue.increment` inside each sale write.
@immutable
class DailyStats {
  const DailyStats({
    required this.dayKey,
    this.salesCentavos = 0,
    this.costCentavos = 0,
    this.transactionCount = 0,
    this.itemsSold = 0,
    this.products = const [],
  });

  factory DailyStats.empty(String dayKey) => DailyStats(dayKey: dayKey);

  factory DailyStats.fromMap(String dayKey, Map<String, Object?> map) {
    final products = map.readMap(StatsFields.products);
    return DailyStats(
      dayKey: dayKey,
      salesCentavos: map.readInt(StatsFields.salesCentavos),
      costCentavos: map.readInt(StatsFields.costCentavos),
      transactionCount: map.readInt(StatsFields.transactionCount),
      itemsSold: map.readInt(StatsFields.itemsSold),
      products: [
        for (final entry in products.entries)
          if (entry.value is Map)
            _productStat(entry.key, entry.value! as Map<Object?, Object?>),
      ],
    );
  }

  static ProductDayStat _productStat(String id, Map<Object?, Object?> raw) {
    final map = raw.map((k, v) => MapEntry(k.toString(), v));
    return ProductDayStat(
      productId: id,
      name: map.readString(StatsFields.productName),
      qty: map.readInt(StatsFields.productQty),
      salesCentavos: map.readInt(StatsFields.productSales),
    );
  }

  final String dayKey;
  final int salesCentavos;
  final int costCentavos;
  final int transactionCount;
  final int itemsSold;
  final List<ProductDayStat> products;

  /// Estimated profit = sales − cost of goods sold.
  int get profitCentavos => salesCentavos - costCentavos;
}
