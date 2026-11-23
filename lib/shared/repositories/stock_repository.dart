import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/stock_movement.dart';
import 'package:tindascan/shared/repositories/paged_result.dart';

/// Stock adjustments and movement history. Throws `Failure` on error.
abstract interface class StockRepository {
  /// Applies [qtyChange] to a product's stock in a transaction and records a
  /// movement. Removals that would make stock negative throw
  /// `InsufficientStock`. Returns the new stock quantity.
  Future<int> adjust({
    required String productId,
    required MovementType type,
    required int qtyChange,
    required String note,
    required AppUser by,
  });

  /// Movement history for one product, newest first.
  Future<PagedResult<StockMovement>> movementsForProduct(
    String productId, {
    Object? after,
    int limit,
  });

  /// All movements in `[from, to)`, newest first, capped (reports).
  Future<List<StockMovement>> movementsBetween(
    DateTime from,
    DateTime to, {
    int limit,
  });
}
