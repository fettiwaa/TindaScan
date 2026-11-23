import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/shared/models/firestore_parsing.dart';

/// A product in the store catalog (`products/{id}`).
///
/// Money is stored in integer centavos. Products are never hard-deleted;
/// [isActive] = false archives them so past sales stay intact.
@immutable
class Product {
  const Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.category,
    required this.unitPriceCentavos,
    required this.costPriceCentavos,
    required this.stockQty,
    required this.lowStockThreshold,
    this.expiryDate,
    this.isActive = true,
    this.hasBarcode = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromMap(String id, Map<String, Object?> map) => Product(
    id: id,
    barcode: map.readString(ProductFields.barcode),
    name: map.readString(ProductFields.name),
    category: map.readString(ProductFields.category),
    unitPriceCentavos: map.readInt(ProductFields.unitPriceCentavos),
    costPriceCentavos: map.readInt(ProductFields.costPriceCentavos),
    stockQty: map.readInt(ProductFields.stockQty),
    lowStockThreshold: map.readInt(ProductFields.lowStockThreshold),
    expiryDate: map.readDateTime(ProductFields.expiryDate),
    isActive: map.readBool(ProductFields.isActive, fallback: true),
    hasBarcode: map.readBool(ProductFields.hasBarcode, fallback: true),
    createdAt: map.readDateTime(ProductFields.createdAt),
    updatedAt: map.readDateTime(ProductFields.updatedAt),
  );

  final String id;

  /// Printed barcode, or an auto-generated internal code when
  /// [hasBarcode] is false.
  final String barcode;
  final String name;

  /// A `ProductCategory` key (stored as text for forward compatibility).
  final String category;
  final int unitPriceCentavos;
  final int costPriceCentavos;

  /// Can go negative only when offline sales oversold (flagged to the owner).
  final int stockQty;
  final int lowStockThreshold;
  final DateTime? expiryDate;
  final bool isActive;
  final bool hasBarcode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Longest word prefix stored for search; longer queries are matched on
  /// this prefix and then filtered on the client.
  static const int maxKeywordLength = 10;

  /// Lower-case prefixes (1..[maxKeywordLength] chars) of every word in
  /// [name], so a query on any word's start can use `arrayContains`.
  static List<String> searchKeywords(String name) {
    final words = name.toLowerCase().split(RegExp(r'[^a-z0-9ñ]+'));
    final keywords = <String>{};
    for (final word in words) {
      for (var i = 1; i <= word.length && i <= maxKeywordLength; i++) {
        keywords.add(word.substring(0, i));
      }
    }
    return keywords.toList();
  }

  /// Search token for [query]: the first word, cut to [maxKeywordLength].
  static String? searchToken(String query) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9ñ]+'))
        .where((w) => w.isNotEmpty);
    if (words.isEmpty) return null;
    final first = words.first;
    return first.length > maxKeywordLength
        ? first.substring(0, maxKeywordLength)
        : first;
  }

  /// Whether every word in [query] starts some word of the name.
  bool matchesSearch(String query) {
    final nameWords = name.toLowerCase().split(RegExp(r'[^a-z0-9ñ]+'));
    final queryWords = query
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9ñ]+'))
        .where((w) => w.isNotEmpty);
    return queryWords.every((q) => nameWords.any((n) => n.startsWith(q)));
  }

  bool get isLowStock => stockQty <= lowStockThreshold;

  bool get isOutOfStock => stockQty <= 0;

  int get profitPerUnitCentavos => unitPriceCentavos - costPriceCentavos;

  /// Expired or expiring within [days] of [now].
  bool expiresWithin(DateTime now, int days) {
    final expiry = expiryDate;
    if (expiry == null) return false;
    return !expiry.isAfter(now.add(Duration(days: days)));
  }

  bool isExpired(DateTime now) {
    final expiry = expiryDate;
    return expiry != null && expiry.isBefore(now);
  }

  /// Editable fields as written to Firestore (timestamps are added by the
  /// repository). Includes the derived `nameLower` and `lowStock` fields.
  Map<String, Object?> toMap() => {
    ProductFields.barcode: barcode,
    ProductFields.name: name,
    ProductFields.nameLower: name.toLowerCase(),
    ProductFields.keywords: searchKeywords(name),
    ProductFields.category: category,
    ProductFields.unitPriceCentavos: unitPriceCentavos,
    ProductFields.costPriceCentavos: costPriceCentavos,
    ProductFields.stockQty: stockQty,
    ProductFields.lowStockThreshold: lowStockThreshold,
    ProductFields.lowStock: isLowStock,
    ProductFields.expiryDate: expiryDate == null
        ? null
        : Timestamp.fromDate(expiryDate!),
    ProductFields.isActive: isActive,
    ProductFields.hasBarcode: hasBarcode,
  };

  Product copyWith({
    String? id,
    String? barcode,
    String? name,
    String? category,
    int? unitPriceCentavos,
    int? costPriceCentavos,
    int? stockQty,
    int? lowStockThreshold,
    DateTime? expiryDate,
    bool clearExpiry = false,
    bool? isActive,
    bool? hasBarcode,
  }) => Product(
    id: id ?? this.id,
    barcode: barcode ?? this.barcode,
    name: name ?? this.name,
    category: category ?? this.category,
    unitPriceCentavos: unitPriceCentavos ?? this.unitPriceCentavos,
    costPriceCentavos: costPriceCentavos ?? this.costPriceCentavos,
    stockQty: stockQty ?? this.stockQty,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
    isActive: isActive ?? this.isActive,
    hasBarcode: hasBarcode ?? this.hasBarcode,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.barcode == barcode &&
      other.name == name &&
      other.category == category &&
      other.unitPriceCentavos == unitPriceCentavos &&
      other.costPriceCentavos == costPriceCentavos &&
      other.stockQty == stockQty &&
      other.lowStockThreshold == lowStockThreshold &&
      other.expiryDate == expiryDate &&
      other.isActive == isActive &&
      other.hasBarcode == hasBarcode;

  @override
  int get hashCode => Object.hash(
    id,
    barcode,
    name,
    category,
    unitPriceCentavos,
    costPriceCentavos,
    stockQty,
    lowStockThreshold,
    expiryDate,
    isActive,
    hasBarcode,
  );
}
