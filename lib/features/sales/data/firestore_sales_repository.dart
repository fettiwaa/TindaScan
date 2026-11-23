import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/core/errors/app_logger.dart';
import 'package:tindascan/core/errors/error_mapper.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/features/sales/domain/cart.dart';
import 'package:tindascan/features/sales/domain/checkout_request.dart';
import 'package:tindascan/features/sales/domain/receipt_number.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/firestore_parsing.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/models/sale.dart';
import 'package:tindascan/shared/models/stock_movement.dart';
import 'package:tindascan/shared/repositories/sales_repository.dart';

typedef _Json = Map<String, Object?>;

/// [SalesRepository] backed by Cloud Firestore.
class FirestoreSalesRepository implements SalesRepository {
  FirestoreSalesRepository(this._db, {void Function(Sale sale)? onSyncLost})
    : _onSyncLost = onSyncLost;

  final FirebaseFirestore _db;

  /// Called when the server rejects an offline sale and it is not on the
  /// server either, i.e. the sale is really lost and must be re-entered.
  final void Function(Sale sale)? _onSyncLost;

  CollectionReference<_Json> get _sales => _db.collection(FirestorePaths.sales);

  CollectionReference<_Json> get _products =>
      _db.collection(FirestorePaths.products);

  CollectionReference<_Json> get _movements =>
      _db.collection(FirestorePaths.stockMovements);

  CollectionReference<_Json> get _counters =>
      _db.collection(FirestorePaths.counters);

  CollectionReference<_Json> get _stats =>
      _db.collection(FirestorePaths.dailyStats);

  @override
  String newSaleId() => _sales.doc().id;

  /// Read cost: 1 (idempotency check) + 1 per cart line + 1 (counter).
  /// Writes: 1 sale + 2 per line + counter + daily stats.
  @override
  Future<Sale> createSale(
    Cart cart,
    int tenderedCentavos, {
    required AppUser cashier,
    required String saleId,
    required DateTime now,
  }) => _transaction(
    CheckoutRequest(
      saleId: saleId,
      cart: cart,
      tenderedCentavos: tenderedCentavos,
      cashier: cashier,
      now: now,
    ),
  );

  @override
  Future<Sale> createSaleOffline(
    Cart cart,
    int tenderedCentavos, {
    required AppUser cashier,
    required String saleId,
    required DateTime now,
  }) => _batch(
    CheckoutRequest(
      saleId: saleId,
      cart: cart,
      tenderedCentavos: tenderedCentavos,
      cashier: cashier,
      now: now,
    ),
  );

  Future<Sale> _transaction(CheckoutRequest request) => guardFailure(() async {
    final saleRef = _sales.doc(request.saleId);
    final dayKey = ManilaTime.dayKey(request.now);
    final counterRef = _counters.doc(
      '${FirestorePaths.receiptCounterPrefix}$dayKey',
    );

    return _db.runTransaction<Sale>((tx) async {
      // Idempotent retry: if this sale already committed (e.g. the response
      // was lost), return it instead of charging twice.
      final existing = await tx.get(saleRef);
      final existingData = existing.data();
      if (existingData != null) return Sale.fromMap(existing.id, existingData);

      // 1. Re-read every product; abort on any change since it was added.
      final fresh = <String, Product>{};
      for (final line in request.cart.lines) {
        final snap = await tx.get(_products.doc(line.product.id));
        final data = snap.data();
        if (data == null) throw ProductNotFound(productName: line.product.name);
        final product = Product.fromMap(snap.id, data);
        if (!product.isActive) throw ProductNotFound(productName: product.name);
        if (product.unitPriceCentavos != line.product.unitPriceCentavos) {
          throw PriceChangedFailure(product.name);
        }
        if (product.stockQty < line.qty) {
          throw InsufficientStock(
            productName: product.name,
            available: product.stockQty < 0 ? 0 : product.stockQty,
          );
        }
        fresh[product.id] = product;
      }

      // 2. Next receipt number for today (collision-safe: same transaction).
      final counter = await tx.get(counterRef);
      final sequence =
          (counter.data() ?? const {}).readInt(CounterFields.seq) + 1;

      final sale = request.buildSale(
        receiptNo: ReceiptNumber.online(dayKey, sequence),
        dayKey: dayKey,
        offline: false,
        products: fresh,
      );
      if (sale.changeCentavos < 0) throw const InvalidPayment();

      // 3. Writes (all reads are done — a Firestore requirement).
      tx.set(saleRef, {
        ...sale.toMap(),
        SaleFields.createdAt: FieldValue.serverTimestamp(),
      });
      for (final line in request.cart.lines) {
        final product = fresh[line.product.id]!;
        final newQty = product.stockQty - line.qty;
        tx
          ..update(_products.doc(product.id), {
            ProductFields.stockQty: newQty,
            ProductFields.lowStock: newQty <= product.lowStockThreshold,
            ProductFields.updatedAt: FieldValue.serverTimestamp(),
            ProductFields.lastSaleId: sale.id,
          })
          ..set(
            _movements.doc('${sale.id}_${product.id}'),
            _saleMovement(sale, product, line.qty),
          );
      }
      tx
        ..set(counterRef, {
          CounterFields.seq: sequence,
          CounterFields.lastSaleId: sale.id,
        })
        ..set(
          _stats.doc(dayKey),
          _statsIncrement(sale),
          SetOptions(merge: true),
        );
      return sale;
    });
  });

  /// Offline trade-off (documented risk):
  /// Firestore transactions need a server round-trip, so without a
  /// connection we write a batch with `FieldValue.increment(-qty)`. The
  /// writes apply to the local cache immediately and sync later. Because
  /// stock is not re-checked on the server, two offline devices can oversell
  /// and stock can go negative after sync; the owner sees these products
  /// under Alerts → Negative stock. If the server rejects the batch when it
  /// syncs, [_onSyncRejected] checks whether the sale is on the server
  /// anyway (an earlier transaction committed but its response was lost) and
  /// otherwise reports it through `onSyncLost` so the cashier can re-enter
  /// it. Limitation: this only works while the app process that made the
  /// sale is still running; a rejection after an app restart is only logged
  /// by Firestore.
  Future<Sale> _batch(CheckoutRequest request) => guardFailure(() async {
    final dayKey = ManilaTime.dayKey(request.now);
    final sale = request.buildSale(
      receiptNo: ReceiptNumber.offline(dayKey, request.saleId),
      dayKey: dayKey,
      offline: true,
    );
    if (sale.changeCentavos < 0) throw const InvalidPayment();

    final batch = _db.batch()
      ..set(_sales.doc(sale.id), {
        ...sale.toMap(),
        SaleFields.createdAt: FieldValue.serverTimestamp(),
      });
    for (final line in request.cart.lines) {
      final product = line.product;
      final expectedQty = product.stockQty - line.qty;
      batch
        ..update(_products.doc(product.id), {
          ProductFields.stockQty: FieldValue.increment(-line.qty),
          ProductFields.lowStock: expectedQty <= product.lowStockThreshold,
          ProductFields.updatedAt: FieldValue.serverTimestamp(),
          ProductFields.lastSaleId: sale.id,
        })
        ..set(
          _movements.doc('${sale.id}_${product.id}'),
          _saleMovement(sale, product, line.qty),
        );
    }
    batch.set(
      _stats.doc(dayKey),
      _statsIncrement(sale),
      SetOptions(merge: true),
    );

    // commit() completes only when the server acknowledges, which may be
    // much later; the local cache is updated right away.
    unawaited(
      batch.commit().catchError((Object error, StackTrace stack) {
        AppLogger.error('Offline sale sync failed', error, stack);
        return _onSyncRejected(sale);
      }),
    );
    return sale;
  });

  Future<void> _onSyncRejected(Sale sale) async {
    try {
      final onServer = await _sales
          .doc(sale.id)
          .get(const GetOptions(source: Source.server));
      // Same id already committed by the online attempt: nothing was lost
      // (the receipt shown was the offline one; the stored sale has the
      // sequential number).
      if (onServer.exists) return;
    } on Object catch (error, stack) {
      // Cannot tell: report it so the cashier double-checks.
      AppLogger.error('Offline sale check', error, stack);
    }
    _onSyncLost?.call(sale);
  }

  /// `waitForPendingWrites` completes once every write made so far is
  /// confirmed; if it does not within [wait], some are still pending.
  @override
  Future<bool> hasUnsyncedSales({
    Duration wait = const Duration(seconds: 3),
  }) async {
    try {
      await _db.waitForPendingWrites().timeout(wait);
      return false;
    } on TimeoutException {
      return true;
    } on Object catch (error, stack) {
      AppLogger.error('Pending writes check', error, stack);
      return false;
    }
  }

  @override
  Future<Sale?> getSale(String id) => guardFailure(() async {
    final snap = await _sales.doc(id).get();
    final data = snap.data();
    return data == null ? null : Sale.fromMap(snap.id, data);
  });

  /// Filters on `dayKey` (the Manila day the sale was made), not
  /// `createdAt` (server time, which for an offline sale is when it
  /// synced), so the Transactions sheet agrees with `daily_stats`.
  /// Read cost: up to [limit] reads (single-field index on dayKey).
  @override
  Future<List<Sale>> salesBetween(
    DateTime from,
    DateTime to, {
    int limit = AppConstants.maxReportSales,
  }) => guardFailure(() async {
    final snap = await _sales
        .where(
          SaleFields.dayKey,
          isGreaterThanOrEqualTo: ManilaTime.dayKey(from),
        )
        .where(SaleFields.dayKey, isLessThan: ManilaTime.dayKey(to))
        .orderBy(SaleFields.dayKey, descending: true)
        .limit(limit)
        .get();
    final sales = [
      for (final doc in snap.docs) Sale.fromMap(doc.id, doc.data()),
    ];
    // Newest first within a day.
    final epoch = DateTime.utc(1970);
    return sales..sort((a, b) {
      final byDay = b.dayKey.compareTo(a.dayKey);
      if (byDay != 0) return byDay;
      return (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch);
    });
  });

  static _Json _saleMovement(Sale sale, Product product, int qty) => {
    ...StockMovement(
      id: '',
      productId: product.id,
      productName: product.name,
      type: MovementType.sale,
      qtyChange: -qty,
      note: sale.receiptNo,
      userId: sale.cashierId,
      userName: sale.cashierName,
      saleId: sale.id,
    ).toMap(),
    MovementFields.createdAt: FieldValue.serverTimestamp(),
  };

  /// Daily aggregate increments — dashboards read these instead of sales.
  static _Json _statsIncrement(Sale sale) {
    final products = <String, Object?>{};
    for (final item in sale.items) {
      products[item.productId] = {
        StatsFields.productName: item.name,
        StatsFields.productQty: FieldValue.increment(item.qty),
        StatsFields.productSales: FieldValue.increment(item.subtotalCentavos),
      };
    }
    return {
      StatsFields.salesCentavos: FieldValue.increment(sale.totalCentavos),
      StatsFields.costCentavos: FieldValue.increment(sale.costTotalCentavos),
      StatsFields.transactionCount: FieldValue.increment(1),
      StatsFields.itemsSold: FieldValue.increment(sale.itemCount),
      StatsFields.products: products,
      StatsFields.lastSaleId: sale.id,
      StatsFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }
}
