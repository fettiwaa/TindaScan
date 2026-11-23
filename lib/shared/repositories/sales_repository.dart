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

  /// Whether this device still has writes (offline sales) that the server
  /// has not confirmed. Waits at most [wait] for them to sync. Firestore
  /// keeps pending writes per account, so they only sync while the same
  /// account is signed in on this phone.
  Future<bool> hasUnsyncedSales({Duration wait});

  /// Sales made on the Manila days in `[from, to)` (by `dayKey`, so an
  /// offline sale counts on the day it was made, not the day it synced),
  /// newest first, capped at [limit] (owner only). [from] and [to] are
  /// Manila midnights.
  Future<List<Sale>> salesBetween(DateTime from, DateTime to, {int limit});
}
