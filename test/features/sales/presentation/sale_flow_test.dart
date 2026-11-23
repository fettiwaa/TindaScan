import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/app.dart';
import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/features/home/presentation/app_shell.dart';
import 'package:tindascan/features/products/data/firestore_product_repository.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

/// Full sale through the real screens on a fake Firestore:
/// search -> cart -> payment sheet -> receipt -> stock decremented.
void main() {
  Future<void> pumpStoreApp(
    WidgetTester tester,
    FakeFirebaseFirestore db, {
    required bool owner,
    FakeAlertNotifier? notifier,
  }) async {
    // A phone-sized screen (bottom navigation bar).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeBackendOverrides(
          db: db,
          user: owner ? testOwner : testStaff,
          notifier: notifier,
        ),
        retry: (_, _) => null,
        child: const TindaScanApp(),
      ),
    );
    await pumpUntil(tester, find.byKey(const Key('app-navigation-bar')));
  }

  Future<void> addBySearch(
    WidgetTester tester,
    String query,
    String productId,
  ) async {
    await tester.enterText(find.byKey(const Key('sell-search')), query);
    await tester.pump(const Duration(milliseconds: 400));
    await pumpUntil(tester, find.byKey(Key('suggestion-$productId')));
    await tester.tap(find.byKey(Key('suggestion-$productId')));
    await pumpUntil(tester, find.byKey(Key('qty-$productId')));
  }

  testWidgets('staff completes a cash sale and stock is decremented', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    await seedStore(db, testStaff);
    final productId = await FirestoreProductRepository(
      db,
    ).createProduct(product(), by: testOwner);

    await pumpStoreApp(tester, db, owner: false);
    // Staff land directly on Sell.
    await pumpUntil(tester, find.byKey(const Key('sell-search')));

    await addBySearch(tester, 'pancit', productId);
    await tester.tap(find.byTooltip('Add one'));
    await settle(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('cart-total')),
        matching: find.text('₱32.00'),
      ),
      findsOneWidget,
    );

    // Charge opens the payment sheet.
    await tester.tap(find.byKey(const Key('charge-button')));
    await pumpUntil(tester, find.byKey(const Key('tendered-field')));
    await tester.enterText(find.byKey(const Key('tendered-field')), '50');
    await settle(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('change-amount')),
        matching: find.text('₱18.00'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirm-sale')));
    await pumpUntil(tester, find.byKey(const Key('new-sale')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Sale complete'), findsOneWidget);
    expect(find.textContaining('-0001'), findsOneWidget);

    // Stock decremented and the sale recorded.
    final stored = await db
        .collection(FirestorePaths.products)
        .doc(productId)
        .get();
    expect(stored.data()?[ProductFields.stockQty], 8);
    final sales = await db.collection(FirestorePaths.sales).get();
    expect(sales.docs.single.data()[SaleFields.totalCentavos], 3200);
    expect(sales.docs.single.data()[SaleFields.cashierId], testStaff.uid);

    // Back to an empty cart.
    await tester.ensureVisible(find.byKey(const Key('new-sale')));
    await tester.tap(find.byKey(const Key('new-sale')));
    await pumpUntil(
      tester,
      find.text('Scan or search a product to start a sale.'),
    );
  });

  testWidgets('cannot add more than the available stock', (tester) async {
    final db = FakeFirebaseFirestore();
    await seedStore(db, testStaff);
    final productId = await FirestoreProductRepository(
      db,
    ).createProduct(product(stock: 1), by: testOwner);
    await pumpStoreApp(tester, db, owner: false);
    await pumpUntil(tester, find.byKey(const Key('sell-search')));
    await addBySearch(tester, 'lucky', productId);

    // The stepper's + is disabled at the stock limit...
    final plus = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Add one'),
        matching: find.byType(IconButton),
      ),
    );
    expect(plus.onPressed, isNull);

    // ...and adding it again from search explains why.
    await addBySearch(tester, 'lucky', productId);
    await settle(tester);
    expect(find.textContaining('Only 1 left'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(Key('qty-$productId'))).data, '1');
  });

  testWidgets('removing a cart line can be undone', (tester) async {
    final db = FakeFirebaseFirestore();
    await seedStore(db, testStaff);
    final productId = await FirestoreProductRepository(
      db,
    ).createProduct(product(), by: testOwner);
    await pumpStoreApp(tester, db, owner: false);
    await pumpUntil(tester, find.byKey(const Key('sell-search')));
    await addBySearch(tester, 'lucky', productId);

    // At quantity 1 the minus button removes the line.
    await tester.tap(find.byTooltip('Remove one'));
    await settle(tester);
    expect(find.byKey(Key('qty-$productId')), findsNothing);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.byKey(Key('qty-$productId')), findsOneWidget);
  });

  testWidgets('staff navigation hides owner-only sections', (tester) async {
    final db = FakeFirebaseFirestore();
    await seedStore(db, testStaff);
    await pumpStoreApp(tester, db, owner: false);
    expect(find.byKey(const Key('nav-${ShellBranch.sell}')), findsOneWidget);
    expect(
      find.byKey(const Key('nav-${ShellBranch.products}')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('nav-${ShellBranch.profile}')), findsOneWidget);
    expect(find.byKey(const Key('nav-${ShellBranch.dashboard}')), findsNothing);
    expect(find.byKey(const Key('nav-${ShellBranch.more}')), findsNothing);
  });

  testWidgets('owner lands on the dashboard with a low-stock badge', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    await seedStore(db, testOwner);
    await FirestoreProductRepository(
      db,
    ).createProduct(product(stock: 1, threshold: 5), by: testOwner);
    final notifier = FakeAlertNotifier();
    await pumpStoreApp(tester, db, owner: true, notifier: notifier);

    await pumpUntil(tester, find.text("Today's sales"));
    expect(find.byKey(const Key('nav-${ShellBranch.more}')), findsOneWidget);
    await pumpUntil(
      tester,
      find.descendant(
        of: find.byKey(const Key('nav-${ShellBranch.more}')),
        matching: find.text('1'),
      ),
    );
    expect(notifier.shown.single.single.stockQty, 1);

    // More lists the owner sections.
    await tester.tap(find.byKey(const Key('nav-${ShellBranch.more}')));
    await pumpUntil(tester, find.text('Reports'));
    expect(find.text('Staff accounts'), findsOneWidget);
    // Let staggered entrance animations finish before the test ends.
    await settle(tester, const Duration(seconds: 2));
  });
}
