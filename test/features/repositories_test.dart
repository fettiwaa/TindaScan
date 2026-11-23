import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/features/dashboard/data/firestore_stats_repository.dart';
import 'package:tindascan/features/products/data/firestore_product_repository.dart';
import 'package:tindascan/features/products/domain/product_category.dart';
import 'package:tindascan/features/products/domain/product_query.dart';
import 'package:tindascan/features/sales/data/firestore_sales_repository.dart';
import 'package:tindascan/features/sales/domain/cart.dart';
import 'package:tindascan/features/sales/domain/checkout_request.dart';
import 'package:tindascan/features/settings/application/seed_data.dart';
import 'package:tindascan/features/stock/data/firestore_stock_repository.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/models/sale.dart';
import 'package:tindascan/shared/models/stock_movement.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreProductRepository products;
  late FirestoreSalesRepository sales;
  late FirestoreStockRepository stock;
  late FirestoreStatsRepository stats;
  final now = DateTime.utc(2026, 11, 19, 3);

  setUp(() {
    db = FakeFirebaseFirestore();
    products = FirestoreProductRepository(db);
    sales = FirestoreSalesRepository(db);
    stock = FirestoreStockRepository(db);
    stats = FirestoreStatsRepository(db);
  });

  Future<Product> create(Product p) async {
    final id = await products.createProduct(
      p,
      by: testOwner,
      initialStockNote: 'Initial',
    );
    return (await products.getProduct(id))!;
  }

  CheckoutRequest request(
    Cart cart, {
    int tendered = 100000,
    String saleId = 'sale-1',
  }) => CheckoutRequest(
    saleId: saleId,
    cart: cart,
    tenderedCentavos: tendered,
    cashier: testStaff,
    now: now,
  );

  /// SalesRepository.createSale with the request's cashier, id and time.
  Future<Sale> createSale(CheckoutRequest r) => sales.createSale(
    r.cart,
    r.tenderedCentavos,
    cashier: r.cashier,
    saleId: r.saleId,
    now: r.now,
  );

  Future<Sale> createSaleOffline(CheckoutRequest r) => sales.createSaleOffline(
    r.cart,
    r.tenderedCentavos,
    cashier: r.cashier,
    saleId: r.saleId,
    now: r.now,
  );

  group('FirestoreProductRepository', () {
    test('creates product, barcode claim and initial movement', () async {
      final p = await create(product(stock: 12));
      expect(p.stockQty, 12);
      final claim = await db
          .collection(FirestorePaths.barcodes)
          .doc(p.barcode)
          .get();
      expect(claim.data()?[BarcodeFields.productId], p.id);
      final moves = await db.collection(FirestorePaths.stockMovements).get();
      expect(moves.docs.single.data()[MovementFields.qtyChange], 12);
    });

    test('rejects a duplicate barcode', () async {
      await create(product());
      await expectLater(
        products.createProduct(product(name: 'Other'), by: testOwner),
        throwsA(isA<DuplicateBarcodeFailure>()),
      );
    });

    test('update keeps stock and moves the barcode claim', () async {
      final p = await create(product(stock: 8));
      await products.updateProduct(
        p.copyWith(
          barcode: '4800000000017',
          stockQty: 999,
          unitPriceCentavos: 1700,
        ),
      );
      final updated = (await products.getProduct(p.id))!;
      expect(updated.stockQty, 8);
      expect(updated.unitPriceCentavos, 1700);
      final codes = await db.collection(FirestorePaths.barcodes).get();
      expect(codes.docs.map((d) => d.id), ['4800000000017']);
    });

    test('search by word, barcode, category and low stock', () async {
      await create(product());
      await create(
        product(
          id: '',
          barcode: '4800194104104',
          name: 'Bear Brand Milk',
          category: ProductCategory.dairy,
          stock: 2,
          threshold: 5,
        ),
      );

      final byWord = await products.fetchPage(
        const ProductQuery(search: 'canton'),
      );
      expect(byWord.items.single.name, 'Lucky Me Pancit Canton');

      final byCode = await products.fetchPage(
        const ProductQuery(search: '4800194104104'),
      );
      expect(byCode.items.single.name, 'Bear Brand Milk');

      final dairy = await products.fetchPage(
        const ProductQuery(category: ProductCategory.dairy),
      );
      expect(dairy.items.single.name, 'Bear Brand Milk');

      final low = await products.fetchPage(
        const ProductQuery(lowStockOnly: true),
      );
      expect(low.items.single.name, 'Bear Brand Milk');
      expect(await products.countLowStock(), 1);

      final suggestions = await products.searchByName('bear');
      expect(suggestions.single.name, 'Bear Brand Milk');
    });

    test('paginates with a cursor', () async {
      for (var i = 0; i < 5; i++) {
        await create(product(barcode: '10000$i', name: 'Item $i'));
      }
      final first = await products.fetchPage(const ProductQuery(), limit: 3);
      expect(first.items, hasLength(3));
      expect(first.hasMore, isTrue);
      final second = await products.fetchPage(
        const ProductQuery(),
        after: first.cursor,
        limit: 3,
      );
      expect(second.items.map((p) => p.name), ['Item 3', 'Item 4']);
      expect(second.hasMore, isFalse);
    });

    test('archive hides from active lists but keeps the document', () async {
      final p = await create(product());
      await products.setActive(p.id, active: false);
      expect((await products.fetchPage(const ProductQuery())).items, isEmpty);
      final archived = await products.fetchPage(
        const ProductQuery(archived: true),
      );
      expect(archived.items.single.id, p.id);
    });

    test('seed data inserts ~20 products once', () async {
      final added = await seedSampleProducts(
        products,
        by: testOwner,
        initialStockNote: 'x',
      );
      expect(added, sampleProducts().length);
      expect(
        await seedSampleProducts(
          products,
          by: testOwner,
          initialStockNote: 'x',
        ),
        0,
      );
    });
  });

  group('FirestoreSalesRepository.checkout', () {
    test('records the sale atomically and decrements stock', () async {
      final p = await create(product());
      final sale = await createSale(
        request(const Cart().add(p, qty: 3), tendered: 5000),
      );

      expect(sale.receiptNo, '20261119-0001');
      expect(sale.totalCentavos, 4800);
      expect(sale.changeCentavos, 200);
      expect((await products.getProduct(p.id))!.stockQty, 7);

      final saleDoc = await db
          .collection(FirestorePaths.sales)
          .doc('sale-1')
          .get();
      expect(saleDoc.data()?[SaleFields.cashierId], testStaff.uid);
      final movement = await db
          .collection(FirestorePaths.stockMovements)
          .doc('sale-1_${p.id}')
          .get();
      expect(movement.data()?[MovementFields.qtyChange], -3);

      final days = await stats.fetchDays([ManilaTime.dayKey(now)]);
      expect(days.single.salesCentavos, 4800);
      expect(days.single.transactionCount, 1);
      expect(days.single.products.single.qty, 3);
    });

    test('receipt numbers increase per day', () async {
      final p = await create(product());
      await createSale(request(const Cart().add(p)));
      final second = await createSale(
        request(const Cart().add(p), saleId: 'sale-2'),
      );
      expect(second.receiptNo, '20261119-0002');
    });

    test('retrying the same sale id does not charge twice', () async {
      final p = await create(product());
      final cart = const Cart().add(p, qty: 2);
      await createSale(request(cart));
      final retry = await createSale(request(cart));
      expect(retry.receiptNo, '20261119-0001');
      expect((await products.getProduct(p.id))!.stockQty, 8);
    });

    test(
      'aborts with no partial writes when stock changed elsewhere',
      () async {
        final a = await create(product());
        final b = await create(
          product(barcode: '4800194104104', name: 'Milk', stock: 5),
        );
        final cart = const Cart().add(a, qty: 2).add(b, qty: 5);
        // Another device sells 3 of B first.
        await stock.adjust(
          productId: b.id,
          type: MovementType.spoilage,
          qtyChange: -3,
          note: '',
          by: testOwner,
        );

        await expectLater(
          createSale(request(cart)),
          throwsA(
            isA<InsufficientStock>().having((f) => f.available, 'available', 2),
          ),
        );
        expect((await products.getProduct(a.id))!.stockQty, 10);
        expect((await db.collection(FirestorePaths.sales).get()).docs, isEmpty);
      },
    );

    test('aborts when the price changed', () async {
      final p = await create(product());
      final cart = const Cart().add(p);
      await products.updateProduct(p.copyWith(unitPriceCentavos: 1800));
      await expectLater(
        createSale(request(cart)),
        throwsA(isA<PriceChangedFailure>()),
      );
    });

    test('rejects insufficient payment', () async {
      final p = await create(product());
      await expectLater(
        createSale(request(const Cart().add(p), tendered: 100)),
        throwsA(isA<InvalidPayment>()),
      );
    });

    test(
      'offline checkout uses increments and an offline receipt number',
      () async {
        final p = await create(product());
        final sale = await createSaleOffline(
          request(const Cart().add(p, qty: 4), saleId: 'abcdef123'),
        );
        expect(sale.offline, isTrue);
        expect(sale.receiptNo, '20261119-XABCDEF');
        // Let the un-awaited batch commit.
        await Future<void>.delayed(Duration.zero);
        expect((await products.getProduct(p.id))!.stockQty, 6);
      },
    );

    test('salesBetween returns sales in range', () async {
      final p = await create(product());
      await createSale(request(const Cart().add(p)));
      final list = await sales.salesBetween(
        DateTime.utc(2000),
        DateTime.now().add(const Duration(days: 1)),
      );
      expect(list.single.id, 'sale-1');
      expect(await sales.getSale('sale-1'), isNotNull);
    });

    test('salesBetween groups by sale day, not by sync time', () async {
      final p = await create(product());
      // Made on 19 Nov (Manila); the fake stamps createdAt with "now".
      await createSaleOffline(request(const Cart().add(p), saleId: 'late1'));
      await Future<void>.delayed(Duration.zero);

      final nov19 = ManilaTime.parseDayKey('20261119');
      final onTheDay = await sales.salesBetween(
        nov19,
        nov19.add(const Duration(days: 1)),
      );
      final dayAfter = await sales.salesBetween(
        nov19.add(const Duration(days: 1)),
        nov19.add(const Duration(days: 2)),
      );
      expect(onTheDay.map((s) => s.id), ['late1']);
      expect(dayAfter, isEmpty);
    });
  });

  group('FirestoreStockRepository', () {
    test('restock and spoilage adjust stock and record movements', () async {
      final p = await create(product(stock: 5));
      expect(
        await stock.adjust(
          productId: p.id,
          type: MovementType.restock,
          qtyChange: 10,
          note: 'Delivery',
          by: testOwner,
        ),
        15,
      );
      expect(
        await stock.adjust(
          productId: p.id,
          type: MovementType.spoilage,
          qtyChange: -13,
          note: '',
          by: testOwner,
        ),
        2,
      );
      final updated = (await products.getProduct(p.id))!;
      expect(updated.isLowStock, isTrue);
      final low = await products.lowStock();
      expect(low.single.id, p.id);

      final history = await stock.movementsForProduct(p.id, limit: 2);
      expect(history.items, hasLength(2));
      expect(history.hasMore, isTrue);
      final rest = await stock.movementsForProduct(
        p.id,
        after: history.cursor,
        limit: 2,
      );
      expect(rest.items, hasLength(1));
    });

    test('cannot remove more than is in stock', () async {
      final p = await create(product(stock: 2));
      await expectLater(
        stock.adjust(
          productId: p.id,
          type: MovementType.spoilage,
          qtyChange: -3,
          note: '',
          by: testOwner,
        ),
        throwsA(isA<InsufficientStock>()),
      );
    });

    test('movementsBetween covers the range', () async {
      final p = await create(product(stock: 2));
      final list = await stock.movementsBetween(
        DateTime.utc(2000),
        DateTime.now().add(const Duration(days: 1)),
      );
      expect(list.single.productId, p.id);
    });
  });

  test('stats repository returns empty days for missing docs', () async {
    final days = await stats.fetchDays(['20260101', '20260102']);
    expect(days.map((d) => d.dayKey), ['20260101', '20260102']);
    expect(days.every((d) => d.transactionCount == 0), isTrue);
  });
}
