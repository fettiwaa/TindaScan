import 'package:flutter/foundation.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/shared/models/product.dart';

/// One line of the suggested restock list.
@immutable
class RestockSuggestion {
  const RestockSuggestion({
    required this.product,
    required this.targetQty,
    required this.qtyNeeded,
  });

  final Product product;
  final int targetQty;
  final int qtyNeeded;
}

/// Restock planning: bring each low-stock product up to
/// `threshold × multiplier` (at least threshold + 1).
abstract final class Restock {
  static int targetFor(
    Product product, {
    int multiplier = AppConstants.restockTargetMultiplier,
  }) {
    final target = product.lowStockThreshold * multiplier;
    return target > product.lowStockThreshold
        ? target
        : product.lowStockThreshold + 1;
  }

  static List<RestockSuggestion> suggestions(
    Iterable<Product> products, {
    int multiplier = AppConstants.restockTargetMultiplier,
  }) {
    final list = <RestockSuggestion>[];
    for (final product in products) {
      if (!product.isActive || !product.isLowStock) continue;
      final target = targetFor(product, multiplier: multiplier);
      final needed = target - product.stockQty;
      if (needed > 0) {
        list.add(
          RestockSuggestion(
            product: product,
            targetQty: target,
            qtyNeeded: needed,
          ),
        );
      }
    }
    list.sort((a, b) => b.qtyNeeded.compareTo(a.qtyNeeded));
    return list;
  }
}

/// How the owner enters an adjustment.
enum AdjustmentMode { restock, spoilage, correction }

/// Converts form input into a signed stock change.
abstract final class StockAdjustment {
  /// For restock/spoilage [input] is a quantity; for correction it is the
  /// actual counted stock. Returns the signed change (0 = nothing to do).
  static int qtyChange({
    required AdjustmentMode mode,
    required int input,
    required int currentStock,
  }) => switch (mode) {
    AdjustmentMode.restock => input,
    AdjustmentMode.spoilage => -input,
    AdjustmentMode.correction => input - currentStock,
  };
}
