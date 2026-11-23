import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/core/errors/error_mapper.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/models/stock_movement.dart';
import 'package:tindascan/shared/repositories/paged_result.dart';
import 'package:tindascan/shared/repositories/stock_repository.dart';

typedef _Json = Map<String, Object?>;

/// [StockRepository] backed by Cloud Firestore.
class FirestoreStockRepository implements StockRepository {
  FirestoreStockRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<_Json> get _products =>
      _db.collection(FirestorePaths.products);

  CollectionReference<_Json> get _movements =>
      _db.collection(FirestorePaths.stockMovements);

  /// Transaction: read current stock, apply the change, write the movement.
  /// Read cost: 1. Writes: 2.
  @override
  Future<int> adjust({
    required String productId,
    required MovementType type,
    required int qtyChange,
    required String note,
    required AppUser by,
  }) => guardFailure(() async {
    final ref = _products.doc(productId);
    return _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) throw const NotFoundFailure();
      final product = Product.fromMap(snap.id, data);
      final newQty = product.stockQty + qtyChange;
      if (qtyChange < 0 && newQty < 0) {
        throw InsufficientStock(
          productName: product.name,
          available: product.stockQty < 0 ? 0 : product.stockQty,
        );
      }
      tx
        ..update(ref, {
          ProductFields.stockQty: newQty,
          ProductFields.lowStock: newQty <= product.lowStockThreshold,
          ProductFields.updatedAt: FieldValue.serverTimestamp(),
        })
        ..set(_movements.doc(), {
          ...StockMovement(
            id: '',
            productId: product.id,
            productName: product.name,
            type: type,
            qtyChange: qtyChange,
            note: note.trim(),
            userId: by.uid,
            userName: by.name,
          ).toMap(),
          MovementFields.createdAt: FieldValue.serverTimestamp(),
        });
      return newQty;
    });
  });

  /// Read cost: up to [limit] per page. Index: (productId, createdAt DESC).
  @override
  Future<PagedResult<StockMovement>> movementsForProduct(
    String productId, {
    Object? after,
    int limit = AppConstants.defaultPageSize,
  }) => guardFailure(() async {
    var query = _movements
        .where(MovementFields.productId, isEqualTo: productId)
        .orderBy(MovementFields.createdAt, descending: true);
    if (after is DocumentSnapshot) query = query.startAfterDocument(after);
    final snap = await query.limit(limit).get();
    return PagedResult(
      items: [
        for (final doc in snap.docs) StockMovement.fromMap(doc.id, doc.data()),
      ],
      cursor: snap.docs.isEmpty ? after : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  });

  /// Read cost: up to [limit] reads (single-field index on createdAt).
  @override
  Future<List<StockMovement>> movementsBetween(
    DateTime from,
    DateTime to, {
    int limit = AppConstants.maxReportMovements,
  }) => guardFailure(() async {
    final snap = await _movements
        .where(
          MovementFields.createdAt,
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        )
        .where(MovementFields.createdAt, isLessThan: Timestamp.fromDate(to))
        .orderBy(MovementFields.createdAt, descending: true)
        .limit(limit)
        .get();
    return [
      for (final doc in snap.docs) StockMovement.fromMap(doc.id, doc.data()),
    ];
  });
}
