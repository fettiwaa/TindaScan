import 'package:flutter/foundation.dart';

import 'package:tindascan/features/products/domain/product_category.dart';

/// Filters for the product list.
@immutable
class ProductQuery {
  const ProductQuery({
    this.search = '',
    this.category,
    this.lowStockOnly = false,
    this.archived = false,
  });

  /// Name prefix (case-insensitive) or an exact barcode when all digits.
  final String search;
  final ProductCategory? category;
  final bool lowStockOnly;

  /// Show archived (soft-deleted) products instead of active ones.
  final bool archived;

  String get normalizedSearch => search.trim().toLowerCase();

  /// Barcode-looking input (digits/hyphens/letters without spaces, 6+ chars
  /// with at least one digit) is looked up exactly instead of by name.
  bool get looksLikeBarcode {
    final s = search.trim();
    return s.length >= 6 &&
        RegExp(r'^[A-Za-z0-9-]+$').hasMatch(s) &&
        RegExp(r'\d').hasMatch(s) &&
        !s.contains(' ');
  }

  ProductQuery copyWith({
    String? search,
    ProductCategory? category,
    bool clearCategory = false,
    bool? lowStockOnly,
    bool? archived,
  }) => ProductQuery(
    search: search ?? this.search,
    category: clearCategory ? null : (category ?? this.category),
    lowStockOnly: lowStockOnly ?? this.lowStockOnly,
    archived: archived ?? this.archived,
  );

  @override
  bool operator ==(Object other) =>
      other is ProductQuery &&
      other.search == search &&
      other.category == category &&
      other.lowStockOnly == lowStockOnly &&
      other.archived == archived;

  @override
  int get hashCode => Object.hash(search, category, lowStockOnly, archived);
}
