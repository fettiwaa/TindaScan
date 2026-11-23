/// Firestore collection and well-known document names.
///
/// Keep every path here so the rules file (`firebase/firestore.rules`) and
/// the Dart code can be cross-checked in one place.
abstract final class FirestorePaths {
  static const String users = 'users';
  static const String products = 'products';
  static const String barcodes = 'barcodes';
  static const String sales = 'sales';
  static const String stockMovements = 'stock_movements';
  static const String dailyStats = 'daily_stats';
  static const String settings = 'settings';
  static const String counters = 'counters';

  /// `settings/setup` — public one-time "owner registered" flag.
  static const String setupDoc = 'setup';

  /// `settings/store` — store name and defaults.
  static const String storeDoc = 'store';

  /// Prefix for per-day receipt counters: `counters/receipts_yyyyMMdd`.
  static const String receiptCounterPrefix = 'receipts_';
}

/// Field names for `users/{uid}`.
abstract final class UserFields {
  static const String name = 'name';
  static const String email = 'email';
  static const String role = 'role';
  static const String active = 'active';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

/// Field names for `settings/*` documents.
abstract final class SettingsFields {
  static const String completed = 'completed';
  static const String completedAt = 'completedAt';
  static const String storeName = 'storeName';
  static const String defaultLowStockThreshold = 'defaultLowStockThreshold';
  static const String updatedAt = 'updatedAt';
}

/// Field names for `products/{id}`.
abstract final class ProductFields {
  static const String barcode = 'barcode';
  static const String name = 'name';
  static const String nameLower = 'nameLower';

  /// Lower-case word prefixes of the name, for "contains word" search.
  static const String keywords = 'keywords';
  static const String category = 'category';
  static const String unitPriceCentavos = 'unitPriceCentavos';
  static const String costPriceCentavos = 'costPriceCentavos';
  static const String stockQty = 'stockQty';
  static const String lowStockThreshold = 'lowStockThreshold';

  /// Derived `stockQty <= lowStockThreshold`, stored so low-stock items can
  /// be queried (Firestore cannot compare two fields in a query).
  static const String lowStock = 'lowStock';
  static const String expiryDate = 'expiryDate';
  static const String isActive = 'isActive';
  static const String hasBarcode = 'hasBarcode';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';

  /// Id of the sale that last lowered the stock (ties staff writes to a
  /// sale in the security rules).
  static const String lastSaleId = 'lastSaleId';
}

/// Field names for `barcodes/{code}` uniqueness documents.
abstract final class BarcodeFields {
  static const String productId = 'productId';
}

/// Field names for `sales/{id}` and its line items.
abstract final class SaleFields {
  static const String receiptNo = 'receiptNo';
  static const String items = 'items';
  static const String itemCount = 'itemCount';
  static const String totalCentavos = 'totalCentavos';
  static const String costTotalCentavos = 'costTotalCentavos';
  static const String amountTenderedCentavos = 'amountTenderedCentavos';
  static const String changeCentavos = 'changeCentavos';
  static const String cashierId = 'cashierId';
  static const String cashierName = 'cashierName';
  static const String createdAt = 'createdAt';
  static const String dayKey = 'dayKey';
  static const String offline = 'offline';

  // Line item fields.
  static const String productId = 'productId';
  static const String barcode = 'barcode';
  static const String name = 'name';
  static const String qty = 'qty';
  static const String unitPriceCentavos = 'unitPriceCentavos';
  static const String costPriceCentavos = 'costPriceCentavos';
  static const String subtotalCentavos = 'subtotalCentavos';
}

/// Field names for `stock_movements/{id}`.
abstract final class MovementFields {
  static const String productId = 'productId';
  static const String productName = 'productName';
  static const String type = 'type';
  static const String qtyChange = 'qtyChange';
  static const String note = 'note';
  static const String userId = 'userId';
  static const String userName = 'userName';
  static const String saleId = 'saleId';
  static const String createdAt = 'createdAt';
}

/// Field names for `daily_stats/{yyyyMMdd}`.
abstract final class StatsFields {
  static const String salesCentavos = 'salesCentavos';
  static const String costCentavos = 'costCentavos';
  static const String transactionCount = 'transactionCount';
  static const String itemsSold = 'itemsSold';

  /// Map of productId -> {name, qty, salesCentavos} for best-sellers.
  static const String products = 'products';
  static const String productName = 'name';
  static const String productQty = 'qty';
  static const String productSales = 'salesCentavos';
  static const String lastSaleId = 'lastSaleId';
  static const String updatedAt = 'updatedAt';
}

/// Field names for `counters/receipts_yyyyMMdd`.
abstract final class CounterFields {
  static const String seq = 'seq';
  static const String lastSaleId = 'lastSaleId';
}
