import 'package:tindascan/features/products/domain/product_query.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/repositories/paged_result.dart';

export 'package:tindascan/shared/repositories/paged_result.dart';

/// Product catalog access. All methods throw a `Failure` on error.
abstract interface class ProductRepository {
  /// Paginated, filtered list (never streams the whole collection).
  Future<PagedResult<Product>> fetchPage(
    ProductQuery query, {
    Object? after,
    int limit,
  });

  /// Exact barcode lookup (1 read). Returns archived products too; callers
  /// decide what to do with them.
  Future<Product?> findByBarcode(String barcode);

  /// Word-prefix suggestions for the Sell screen (active products only),
  /// e.g. "pan" matches "Lucky Me Pancit Canton".
  Future<List<Product>> searchByName(String prefix, {int limit});

  Future<Product?> getProduct(String id);

  Stream<Product?> watchProduct(String id);

  /// Creates a product and claims its barcode atomically. When
  /// `product.stockQty > 0`, also records an initial restock movement.
  /// Throws `DuplicateBarcodeFailure`. Returns the new id.
  Future<String> createProduct(
    Product product, {
    required AppUser by,
    String initialStockNote,
  });

  /// Updates editable fields (not stock — use stock adjustments). Re-claims
  /// the barcode atomically when it changed.
  Future<void> updateProduct(Product product);

  /// Archives (soft delete) or restores a product.
  Future<void> setActive(String id, {required bool active});

  /// Active products at or below their threshold, lowest stock first.
  Future<List<Product>> lowStock({int limit});

  /// Number of active low-stock products (aggregate count, 1 read per 1000).
  Future<int> countLowStock();

  /// Active products with negative stock (offline overselling).
  Future<List<Product>> negativeStock({int limit});

  /// Active products expiring on or before [before], soonest first.
  Future<List<Product>> expiringBefore(DateTime before, {int limit});

  /// Active products with the lowest stock (dashboard chart).
  Future<List<Product>> lowestStock({int limit});

  /// All active products for the inventory report, capped at [limit].
  Future<List<Product>> allActive({int limit});
}
