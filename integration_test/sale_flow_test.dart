// End-to-end sale on a device/emulator:
//   flutter test integration_test/sale_flow_test.dart
//
// Runs the real app UI on an in-memory Firestore (no cloud project needed),
// so it is deterministic and costs no Firebase reads.
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:tindascan/app.dart';
import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/features/products/data/firestore_product_repository.dart';

import '../test/helpers/fixtures.dart';
import '../test/helpers/mocks.dart';
import '../test/helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('search -> cart -> pay -> stock decremented', (tester) async {
    final db = FakeFirebaseFirestore();
    await seedStore(db, testStaff);
    final productId = await FirestoreProductRepository(
      db,
    ).createProduct(product(), by: testOwner);

    await tester.pumpWidget(
      ProviderScope(
        overrides: fakeBackendOverrides(db: db, user: testStaff),
        child: const TindaScanApp(),
      ),
    );

    await pumpUntil(tester, find.byKey(const Key('home-${AppRoutes.sell}')));
    await tester.tap(find.byKey(const Key('home-${AppRoutes.sell}')));
    await pumpUntil(tester, find.byKey(const Key('sell-search')));

    await tester.enterText(find.byKey(const Key('sell-search')), 'canton');
    await tester.pump(const Duration(milliseconds: 400));
    await pumpUntil(tester, find.byKey(Key('suggestion-$productId')));
    await tester.tap(find.byKey(Key('suggestion-$productId')));
    await pumpUntil(tester, find.byKey(const Key('charge-button')));

    await tester.tap(find.byKey(const Key('charge-button')));
    await pumpUntil(tester, find.byKey(const Key('tendered-field')));
    await tester.enterText(find.byKey(const Key('tendered-field')), '20');
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-sale')));
    await pumpUntil(tester, find.byKey(const Key('new-sale')));

    final stored = await db
        .collection(FirestorePaths.products)
        .doc(productId)
        .get();
    expect(stored.data()?[ProductFields.stockQty], 9);
    expect(find.text('₱4.00'), findsWidgets); // change from ₱20
  });
}
