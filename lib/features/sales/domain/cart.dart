import 'package:flutter/foundation.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/shared/models/product.dart';

/// One product in the cart with a quantity. [product] is the snapshot taken
/// when it was added (refreshed if checkout detects a change).
@immutable
class CartLine {
  const CartLine({required this.product, required this.qty});

  final Product product;
  final int qty;

  int get subtotalCentavos => product.unitPriceCentavos * qty;

  int get costSubtotalCentavos => product.costPriceCentavos * qty;

  CartLine copyWith({Product? product, int? qty}) =>
      CartLine(product: product ?? this.product, qty: qty ?? this.qty);

  @override
  bool operator ==(Object other) =>
      other is CartLine && other.product == product && other.qty == qty;

  @override
  int get hashCode => Object.hash(product, qty);
}

/// Immutable shopping cart with stock validation. Every mutation returns a
/// new cart or throws a `Failure` explaining why it was refused.
@immutable
class Cart {
  const Cart([this.lines = const []]);

  final List<CartLine> lines;

  bool get isEmpty => lines.isEmpty;

  int get totalCentavos =>
      lines.fold(0, (sum, line) => sum + line.subtotalCentavos);

  int get costTotalCentavos =>
      lines.fold(0, (sum, line) => sum + line.costSubtotalCentavos);

  /// Number of units (not lines).
  int get itemCount => lines.fold(0, (sum, line) => sum + line.qty);

  int quantityOf(String productId) {
    for (final line in lines) {
      if (line.product.id == productId) return line.qty;
    }
    return 0;
  }

  /// Adds [qty] units (merging with an existing line). Throws
  /// [InsufficientStock] when it would exceed available stock and
  /// [ProductNotFound] for archived products.
  Cart add(Product product, {int qty = 1}) {
    if (!product.isActive) throw ProductNotFound(productName: product.name);
    final existing = quantityOf(product.id);
    if (existing == 0 && lines.length >= AppConstants.maxCartLines) {
      throw const ConflictFailure();
    }
    return setQuantity(product, existing + qty);
  }

  /// Sets the quantity of [product]; 0 or less removes the line.
  Cart setQuantity(Product product, int qty) {
    if (qty <= 0) return remove(product.id);
    final available = product.stockQty < 0 ? 0 : product.stockQty;
    if (qty > available || qty > AppConstants.maxQuantity) {
      throw InsufficientStock(productName: product.name, available: available);
    }
    final index = lines.indexWhere((l) => l.product.id == product.id);
    final updated = [...lines];
    if (index == -1) {
      updated.add(CartLine(product: product, qty: qty));
    } else {
      updated[index] = CartLine(product: product, qty: qty);
    }
    return Cart(List.unmodifiable(updated));
  }

  Cart remove(String productId) =>
      Cart(List.unmodifiable(lines.where((l) => l.product.id != productId)));

  /// Replaces product snapshots with fresh data. Lines whose product is gone
  /// or archived are dropped; quantities are clamped to available stock.
  Cart refresh(Map<String, Product?> fresh) {
    final updated = <CartLine>[];
    for (final line in lines) {
      final product = fresh.containsKey(line.product.id)
          ? fresh[line.product.id]
          : line.product;
      if (product == null || !product.isActive || product.stockQty <= 0) {
        continue;
      }
      final qty = line.qty > product.stockQty ? product.stockQty : line.qty;
      updated.add(CartLine(product: product, qty: qty));
    }
    return Cart(List.unmodifiable(updated));
  }

  @override
  bool operator ==(Object other) =>
      other is Cart && listEquals(other.lines, lines);

  @override
  int get hashCode => Object.hashAll(lines);
}
