import 'package:flutter/foundation.dart';

import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/shared/models/firestore_parsing.dart';

/// One line of a completed sale. Prices are copied at sale time so later
/// price changes never alter history.
@immutable
class SaleItem {
  const SaleItem({
    required this.productId,
    required this.barcode,
    required this.name,
    required this.qty,
    required this.unitPriceCentavos,
    required this.costPriceCentavos,
  });

  factory SaleItem.fromMap(Map<String, Object?> map) => SaleItem(
    productId: map.readString(SaleFields.productId),
    barcode: map.readString(SaleFields.barcode),
    name: map.readString(SaleFields.name),
    qty: map.readInt(SaleFields.qty),
    unitPriceCentavos: map.readInt(SaleFields.unitPriceCentavos),
    costPriceCentavos: map.readInt(SaleFields.costPriceCentavos),
  );

  final String productId;
  final String barcode;
  final String name;
  final int qty;
  final int unitPriceCentavos;
  final int costPriceCentavos;

  int get subtotalCentavos => unitPriceCentavos * qty;

  int get costSubtotalCentavos => costPriceCentavos * qty;

  Map<String, Object?> toMap() => {
    SaleFields.productId: productId,
    SaleFields.barcode: barcode,
    SaleFields.name: name,
    SaleFields.qty: qty,
    SaleFields.unitPriceCentavos: unitPriceCentavos,
    SaleFields.costPriceCentavos: costPriceCentavos,
    SaleFields.subtotalCentavos: subtotalCentavos,
  };

  @override
  bool operator ==(Object other) =>
      other is SaleItem &&
      other.productId == productId &&
      other.barcode == barcode &&
      other.name == name &&
      other.qty == qty &&
      other.unitPriceCentavos == unitPriceCentavos &&
      other.costPriceCentavos == costPriceCentavos;

  @override
  int get hashCode => Object.hash(
    productId,
    barcode,
    name,
    qty,
    unitPriceCentavos,
    costPriceCentavos,
  );
}

/// An immutable sale record (`sales/{id}`).
@immutable
class Sale {
  const Sale({
    required this.id,
    required this.receiptNo,
    required this.items,
    required this.totalCentavos,
    required this.costTotalCentavos,
    required this.amountTenderedCentavos,
    required this.changeCentavos,
    required this.cashierId,
    required this.cashierName,
    required this.dayKey,
    this.createdAt,
    this.offline = false,
  });

  factory Sale.fromMap(String id, Map<String, Object?> map) => Sale(
    id: id,
    receiptNo: map.readString(SaleFields.receiptNo),
    items: [
      for (final item in map.readMapList(SaleFields.items))
        SaleItem.fromMap(item),
    ],
    totalCentavos: map.readInt(SaleFields.totalCentavos),
    costTotalCentavos: map.readInt(SaleFields.costTotalCentavos),
    amountTenderedCentavos: map.readInt(SaleFields.amountTenderedCentavos),
    changeCentavos: map.readInt(SaleFields.changeCentavos),
    cashierId: map.readString(SaleFields.cashierId),
    cashierName: map.readString(SaleFields.cashierName),
    dayKey: map.readString(SaleFields.dayKey),
    createdAt: map.readDateTime(SaleFields.createdAt),
    offline: map.readBool(SaleFields.offline),
  );

  final String id;

  /// `yyyyMMdd-0001` online; `yyyyMMdd-X` + id fragment when made offline.
  final String receiptNo;
  final List<SaleItem> items;
  final int totalCentavos;
  final int costTotalCentavos;
  final int amountTenderedCentavos;
  final int changeCentavos;
  final String cashierId;
  final String cashierName;
  final String dayKey;

  /// Server time (local estimate until the write is acknowledged).
  final DateTime? createdAt;

  /// Recorded without a connection (batched write, synced later).
  final bool offline;

  int get itemCount => items.fold(0, (sum, item) => sum + item.qty);

  int get profitCentavos => totalCentavos - costTotalCentavos;

  /// Fields written on creation; `createdAt` is added by the repository.
  Map<String, Object?> toMap() => {
    SaleFields.receiptNo: receiptNo,
    SaleFields.items: [for (final item in items) item.toMap()],
    SaleFields.itemCount: itemCount,
    SaleFields.totalCentavos: totalCentavos,
    SaleFields.costTotalCentavos: costTotalCentavos,
    SaleFields.amountTenderedCentavos: amountTenderedCentavos,
    SaleFields.changeCentavos: changeCentavos,
    SaleFields.cashierId: cashierId,
    SaleFields.cashierName: cashierName,
    SaleFields.dayKey: dayKey,
    SaleFields.offline: offline,
  };
}
