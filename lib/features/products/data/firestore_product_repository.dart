import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/core/errors/error_mapper.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/features/products/domain/product_query.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/models/stock_movement.dart';
import 'package:tindascan/shared/repositories/product_repository.dart';

typedef _Json = Map<String, Object?>;

/// [ProductRepository] backed by Cloud Firestore.
///
/// Every query is narrowed with `where`/`orderBy` (backed by an index in
/// `firebase/firestore.indexes.json`) and bounded with `limit`, so read cost
/// is proportional to what is shown, never to the catalog size.
class FirestoreProductRepository implements ProductRepository {
  FirestoreProductRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<_Json> get _products =>
      _db.collection(FirestorePaths.products);

  CollectionReference<_Json> get _barcodes =>
      _db.collection(FirestorePaths.barcodes);

  CollectionReference<_Json> get _movements =>
      _db.collection(FirestorePaths.stockMovements);

  Query<_Json> get _active =>
      _products.where(ProductFields.isActive, isEqualTo: true);

  static List<Product> _toProducts(QuerySnapshot<_Json> snap) => [
    for (final doc in snap.docs) Product.fromMap(doc.id, doc.data()),
  ];

  /// Read cost: up to [limit] reads per page (1 read for a barcode match).
  /// Indexes: (isActive, keywords CONTAINS, nameLower),
  /// (isActive, category, keywords CONTAINS, nameLower),
  /// (isActive, category, nameLower), (isActive, nameLower),
  /// (isActive, lowStock, stockQty).
  @override
  Future<PagedResult<Product>> fetchPage(
    ProductQuery query, {
    Object? after,
    int limit = AppConstants.defaultPageSize,
  }) => guardFailure(() async {
    if (query.looksLikeBarcode && after == null) {
      final match = await findByBarcode(query.search.trim());
      final visible = match != null && match.isActive != query.archived;
      if (visible) {
        return PagedResult(items: [match], cursor: null, hasMore: false);
      }
      // Not a known barcode: fall through to a name search.
    }

    var q = _products.where(ProductFields.isActive, isEqualTo: !query.archived);

    if (query.lowStockOnly) {
      // Low-stock items are few; filter search/category on the client.
      final snap = await q
          .where(ProductFields.lowStock, isEqualTo: true)
          .orderBy(ProductFields.stockQty)
          .limit(AppConstants.maxAlertItems)
          .get();
      final items = _toProducts(snap).where((p) {
        final categoryOk =
            query.category == null || p.category == query.category!.key;
        final searchOk =
            query.normalizedSearch.isEmpty ||
            p.matchesSearch(query.normalizedSearch);
        return categoryOk && searchOk;
      }).toList();
      return PagedResult(items: items, cursor: null, hasMore: false);
    }

    if (query.category != null) {
      q = q.where(ProductFields.category, isEqualTo: query.category!.key);
    }
    final token = Product.searchToken(query.normalizedSearch);
    if (token != null) {
      q = q.where(ProductFields.keywords, arrayContains: token);
    }
    q = q.orderBy(ProductFields.nameLower);
    if (after is DocumentSnapshot) q = q.startAfterDocument(after);

    final snap = await q.limit(limit).get();
    final items = _toProducts(
      snap,
    ).where((p) => p.matchesSearch(query.normalizedSearch)).toList();
    return PagedResult(
      items: items,
      cursor: snap.docs.isEmpty ? after : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  });

  /// Read cost: 1 read (single-field index on `barcode`).
  @override
  Future<Product?> findByBarcode(String barcode) => guardFailure(() async {
    final snap = await _products
        .where(ProductFields.barcode, isEqualTo: barcode)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return Product.fromMap(doc.id, doc.data());
  });

  /// Read cost: up to [limit] reads.
  @override
  Future<List<Product>> searchByName(
    String prefix, {
    int limit = AppConstants.searchSuggestionLimit,
  }) => guardFailure(() async {
    final token = Product.searchToken(prefix);
    if (token == null) return const <Product>[];
    final snap = await _active
        .where(ProductFields.keywords, arrayContains: token)
        .orderBy(ProductFields.nameLower)
        .limit(limit)
        .get();
    return _toProducts(snap).where((p) => p.matchesSearch(prefix)).toList();
  });

  @override
  Future<Product?> getProduct(String id) => guardFailure(() async {
    final snap = await _products.doc(id).get();
    final data = snap.data();
    return data == null ? null : Product.fromMap(snap.id, data);
  });

  /// Read cost: 1 read on listen + 1 per change.
  @override
  Stream<Product?> watchProduct(String id) => _products
      .doc(id)
      .snapshots()
      .map((snap) {
        final data = snap.data();
        return data == null ? null : Product.fromMap(snap.id, data);
      })
      .handleError((Object e) => throw mapError(e));

  /// Transaction: verify the barcode is free, then create the product, the
  /// `barcodes/{code}` claim and (if stocked) an initial movement together.
  @override
  Future<String> createProduct(
    Product product, {
    required AppUser by,
    String initialStockNote = '',
  }) => guardFailure(() async {
    final ref = _products.doc();
    final codeRef = _barcodes.doc(product.barcode);
    await _db.runTransaction<void>((tx) async {
      final claim = await tx.get(codeRef);
      if (claim.exists) throw DuplicateBarcodeFailure(product.barcode);
      tx
        ..set(ref, {
          ...product.copyWith(isActive: true).toMap(),
          ProductFields.createdAt: FieldValue.serverTimestamp(),
          ProductFields.updatedAt: FieldValue.serverTimestamp(),
        })
        ..set(codeRef, {BarcodeFields.productId: ref.id});
      if (product.stockQty > 0) {
        tx.set(_movements.doc(), {
          ...StockMovement(
            id: '',
            productId: ref.id,
            productName: product.name,
            type: MovementType.restock,
            qtyChange: product.stockQty,
            note: initialStockNote,
            userId: by.uid,
            userName: by.name,
          ).toMap(),
          MovementFields.createdAt: FieldValue.serverTimestamp(),
        });
      }
    });
    return ref.id;
  });

  /// Transaction: keeps the stored stock (only adjustments change stock) and
  /// moves the barcode claim if the barcode changed.
  @override
  Future<void> updateProduct(Product product) => guardFailure(() async {
    final ref = _products.doc(product.id);
    await _db.runTransaction<void>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) throw const NotFoundFailure();
      final current = Product.fromMap(snap.id, data);

      if (current.barcode != product.barcode) {
        final newClaimRef = _barcodes.doc(product.barcode);
        final newClaim = await tx.get(newClaimRef);
        final owner = newClaim.data()?[BarcodeFields.productId];
        if (newClaim.exists && owner != product.id) {
          throw DuplicateBarcodeFailure(product.barcode);
        }
        tx
          ..delete(_barcodes.doc(current.barcode))
          ..set(newClaimRef, {BarcodeFields.productId: product.id});
      }

      final updated = product.copyWith(stockQty: current.stockQty);
      tx.update(ref, {
        ...updated.toMap(),
        ProductFields.updatedAt: FieldValue.serverTimestamp(),
      });
    });
  });

  @override
  Future<void> setActive(String id, {required bool active}) => guardFailure(
    () => _products.doc(id).update({
      ProductFields.isActive: active,
      ProductFields.updatedAt: FieldValue.serverTimestamp(),
    }),
  );

  /// Read cost: up to [limit] reads. Index: (isActive, lowStock, stockQty).
  @override
  Future<List<Product>> lowStock({int limit = AppConstants.maxAlertItems}) =>
      guardFailure(() async {
        final snap = await _active
            .where(ProductFields.lowStock, isEqualTo: true)
            .orderBy(ProductFields.stockQty)
            .limit(limit)
            .get();
        return _toProducts(snap);
      });

  /// Read cost: 1 read per 1000 matching docs (aggregate count).
  @override
  Future<int> countLowStock() => guardFailure(() async {
    final snap = await _active
        .where(ProductFields.lowStock, isEqualTo: true)
        .count()
        .get();
    return snap.count ?? 0;
  });

  /// Read cost: up to [limit] reads. Index: (isActive, stockQty).
  @override
  Future<List<Product>> negativeStock({
    int limit = AppConstants.maxAlertItems,
  }) => guardFailure(() async {
    final snap = await _active
        .where(ProductFields.stockQty, isLessThan: 0)
        .orderBy(ProductFields.stockQty)
        .limit(limit)
        .get();
    return _toProducts(snap);
  });

  /// Read cost: up to [limit] reads. Index: (isActive, expiryDate).
  @override
  Future<List<Product>> expiringBefore(
    DateTime before, {
    int limit = AppConstants.maxAlertItems,
  }) => guardFailure(() async {
    final snap = await _active
        .where(
          ProductFields.expiryDate,
          isLessThanOrEqualTo: Timestamp.fromDate(before),
        )
        .orderBy(ProductFields.expiryDate)
        .limit(limit)
        .get();
    return _toProducts(snap);
  });

  /// Read cost: [limit] reads. Index: (isActive, stockQty).
  @override
  Future<List<Product>> lowestStock({
    int limit = AppConstants.stockChartItemCount,
  }) => guardFailure(() async {
    final snap = await _active
        .orderBy(ProductFields.stockQty)
        .limit(limit)
        .get();
    return _toProducts(snap);
  });

  /// Read cost: up to [limit] reads. Index: (isActive, nameLower).
  @override
  Future<List<Product>> allActive({
    int limit = AppConstants.maxReportProducts,
  }) => guardFailure(() async {
    final snap = await _active
        .orderBy(ProductFields.nameLower)
        .limit(limit)
        .get();
    return _toProducts(snap);
  });
}
