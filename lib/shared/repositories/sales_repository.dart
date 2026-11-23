import 'package:tindascan/features/sales/domain/cart.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/sale.dart';

/// Sales persistence (F-01 data layer). All methods throw a typed `Failure`
/// (`InsufficientStock`, `ProductNotFound`, `InvalidPayment`,
/// `PermissionDenied`, `NetworkUnavailable`, ...) and never a raw exception.
abstract interface class SalesRepository {
  /// A new, random sale id (no network needed). Used as the idempotency key
  /// for one cart's checkout.
  String newSaleId();

  /// Records a sale atomically in one Firestore transaction:
  /// (1) re-reads each product's stock and aborts if insufficient,
  /// (2) creates `sales/{saleId}` with a per-day receipt number
  ///     (YYYYMMDD-0001) from a counter read in the same transaction,
  /// (3) decrements `stockQty`, (4) writes `stock_movements`, and
  /// (5) increments `daily_stats`. Nothing is written on failure.
  ///
  /// [cashier], [saleId] and [now] are supplied by `CheckoutService`.
  /// Retrying with the same [saleId] returns the existing sale instead of
  /// charging twice. Requires a connection.
  Future<Sale> createSale(
    Cart cart,
    int tenderedCentavos, {
    required AppUser cashier,
    required String saleId,
    required DateTime now,
  });

  /// Offline fallback: a batched write with `FieldValue.increment`, applied
  /// to the local cache immediately and synced by Firestore later. Stock is
  /// not re-checked on the server (documented risk: negative stock).
  Future<Sale> createSaleOffline(
    Cart cart,
    int tenderedCentavos, {
    required AppUser cashier,
    required String saleId,
    required DateTime now,
  });

  Future<Sale?> getSale(String id);

  /// Sales in `[from, to)`, newest first, capped at [limit] (owner only).
  Future<List<Sale>> salesBetween(DateTime from, DateTime to, {int limit});
}
