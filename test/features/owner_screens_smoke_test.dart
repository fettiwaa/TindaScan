import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/app.dart';
import 'package:tindascan/core/router/app_router.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/features/products/data/firestore_product_repository.dart';
import 'package:tindascan/features/sales/data/firestore_sales_repository.dart';
import 'package:tindascan/features/sales/domain/cart.dart';
import 'package:tindascan/features/settings/application/seed_data.dart';
import 'package:tindascan/shared/models/product.dart';

import '../helpers/mocks.dart';
import '../helpers/test_app.dart';

/// Opens every owner screen on seeded data and checks each renders without
/// exceptions (including at 1.5x text scale for the busiest screens).
void main() {
  late FakeFirebaseFirestore db;
  late String productId;

  Future<void> seed() async {
    db = FakeFirebaseFirestore();
    await seedStore(db, testOwner);
    final repo = FirestoreProductRepository(db);
    await seedSampleProducts(repo, by: testOwner, initialStockNote: 'Initial');
    final first = (await repo.searchByName('lucky')).first;
    productId = first.id;
    await FirestoreSalesRepository(db).createSale(
      const Cart().add(first, qty: 2),
      10000,
      cashier: testOwner,
      saleId: 'sale-1',
      now: DateTime.now(),
    );
  }

  Future<void> openAndCheck(
    WidgetTester tester,
    String route,
    Finder expected, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        // A fresh scope (and router) for every screen opened.
        key: UniqueKey(),
        overrides: fakeBackendOverrides(db: db, user: testOwner),
        retry: (_, _) => null,
        child: const TindaScanApp(),
      ),
    );
    await pumpUntil(tester, find.byKey(const Key('app-navigation-bar')));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TindaScanApp)),
    );
    container.read(routerProvider).go(route);
    await pumpUntil(tester, expected);
    // Let entrance animations (and their timers) finish.
    await settle(tester, const Duration(seconds: 2));
    expect(tester.takeException(), isNull, reason: route);
  }

  final cases = <String, Finder Function()>{
    AppRoutes.products: () => find.text('Argentina Corned Beef 150g'),
    AppRoutes.dashboard: () => find.text("Today's sales"),
    AppRoutes.more: () => find.text('Reports'),
    AppRoutes.alerts: () => find.text('SkyFlakes Crackers 25g'),
    AppRoutes.stock: () => find.text('Suggested restock'),
    AppRoutes.reports: () => find.byKey(const Key('export-excel')),
    AppRoutes.settings: () => find.text('Appearance'),
    AppRoutes.staff: () => find.text('Staff accounts'),
    AppRoutes.productNew: () => find.byKey(const Key('product-save')),
  };

  for (final entry in cases.entries) {
    testWidgets('owner can open ${entry.key}', (tester) async {
      await seed();
      await openAndCheck(tester, entry.key, entry.value());
    });
  }

  testWidgets('product detail, edit, stock and history open', (tester) async {
    await seed();
    for (final route in [
      AppRoutes.productDetail(productId),
      AppRoutes.productEdit(productId),
      AppRoutes.productStock(productId),
      AppRoutes.productHistory(productId),
    ]) {
      await openAndCheck(tester, route, find.byType(Scaffold));
    }
  });

  testWidgets('dashboard and sell render at 1.5x text scale', (tester) async {
    await seed();
    await openAndCheck(
      tester,
      AppRoutes.dashboard,
      find.text("Today's sales"),
      textScale: 1.5,
    );
    // Scroll through every card so all of them lay out at 1.5x.
    for (var i = 0; i < 6; i++) {
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -600),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    }
    expect(find.text('Lowest stock'), findsOneWidget);
    await settle(tester, const Duration(seconds: 2));
    await openAndCheck(
      tester,
      AppRoutes.sell,
      find.byKey(const Key('sell-search')),
      textScale: 1.5,
    );
  });

  testWidgets('dashboard shows today totals from daily stats', (tester) async {
    await seed();
    await openAndCheck(tester, AppRoutes.dashboard, find.text("Today's sales"));
    // 2 x ₱16.00 sold in the seeded sale (hero card counts up to it).
    expect(
      find.descendant(
        of: find.byKey(const Key('today-sales')),
        matching: find.text('₱32.00'),
      ),
      findsOneWidget,
    );
  });

  test('sample data is realistic', () {
    final list = sampleProducts();
    expect(list.length, greaterThanOrEqualTo(20));
    expect(list.map((p) => p.barcode).toSet(), hasLength(list.length));
    expect(list.every((Product p) => p.barcode.length == 13), isTrue);
  });
}
