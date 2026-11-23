import 'package:flutter/foundation.dart';

import 'package:tindascan/features/sales/domain/cart.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/models/sale.dart';

/// Everything needed to record a sale.
@immutable
class CheckoutRequest {
  const CheckoutRequest({
    required this.saleId,
    required this.cart,
    required this.tenderedCentavos,
    required this.cashier,
    required this.now,
  });

  /// Generated once per payment attempt and reused on retry, which makes
  /// submission idempotent: a retried request finds the existing sale.
  final String saleId;
  final Cart cart;
  final int tenderedCentavos;
  final AppUser cashier;

  /// Device time, used only for the Manila day key; the stored timestamp is
  /// the server's.
  final DateTime now;

  /// Builds the sale record using [products] (fresh data read inside the
  /// transaction; defaults to the cart's snapshots).
  Sale buildSale({
    required String receiptNo,
    required String dayKey,
    required bool offline,
    Map<String, Product>? products,
  }) {
    final items = [
      for (final line in cart.lines)
        _item(products?[line.product.id] ?? line.product, line.qty),
    ];
    final total = items.fold(0, (sum, i) => sum + i.subtotalCentavos);
    final cost = items.fold(0, (sum, i) => sum + i.costSubtotalCentavos);
    return Sale(
      id: saleId,
      receiptNo: receiptNo,
      items: items,
      totalCentavos: total,
      costTotalCentavos: cost,
      amountTenderedCentavos: tenderedCentavos,
      changeCentavos: tenderedCentavos - total,
      cashierId: cashier.uid,
      cashierName: cashier.name,
      dayKey: dayKey,
      createdAt: now,
      offline: offline,
    );
  }

  static SaleItem _item(Product p, int qty) => SaleItem(
    productId: p.id,
    barcode: p.barcode,
    name: p.name,
    qty: qty,
    unitPriceCentavos: p.unitPriceCentavos,
    costPriceCentavos: p.costPriceCentavos,
  );
}
