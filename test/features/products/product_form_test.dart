import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/products/presentation/product_form_screen.dart';
import 'package:tindascan/features/settings/application/settings_providers.dart';
import 'package:tindascan/shared/models/store_settings.dart';
import 'package:tindascan/shared/providers/firebase_providers.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

void main() {
  late FakeFirebaseFirestore db;

  Future<void> pumpForm(WidgetTester tester, {String? barcode}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await pumpRouterApp(
      tester,
      initialLocation: '/new',
      overrides: [
        firestoreProvider.overrideWithValue(db),
        currentUserProvider.overrideWithValue(testOwner),
        storeSettingsProvider.overrideWith(
          (ref) => Stream.value(StoreSettings.fallback),
        ),
      ],
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/new',
          builder: (_, _) => ProductFormScreen(initialBarcode: barcode),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (_, state) => Text('detail ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pump();
  }

  setUp(() => db = FakeFirebaseFirestore());

  testWidgets('shows validation errors and does not save', (tester) async {
    await pumpForm(tester);
    await tester.ensureVisible(find.byKey(const Key('product-save')));
    await tester.tap(find.byKey(const Key('product-save')));
    await tester.pump();
    expect(find.text('This field is required.'), findsWidgets);
    expect((await db.collection(FirestorePaths.products).get()).docs, isEmpty);
  });

  testWidgets('prefills the scanned barcode and saves a product', (
    tester,
  ) async {
    await pumpForm(tester, barcode: '4800016644283');
    expect(find.text('4800016644283'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('product-name')),
      'Pancit Canton',
    );
    await tester.enterText(find.byKey(const Key('product-price')), '16');
    await tester.enterText(find.byKey(const Key('product-cost')), '12.50');
    await tester.enterText(find.byKey(const Key('product-stock')), '24');
    await tester.ensureVisible(find.byKey(const Key('product-save')));
    await tester.tap(find.byKey(const Key('product-save')));
    await pumpUntil(tester, find.textContaining('detail '));

    final docs = (await db.collection(FirestorePaths.products).get()).docs;
    final data = docs.single.data();
    expect(data[ProductFields.unitPriceCentavos], 1600);
    expect(data[ProductFields.costPriceCentavos], 1250);
    expect(data[ProductFields.stockQty], 24);
    expect(data[ProductFields.isActive], isTrue);
  });

  testWidgets('warns when price is below cost', (tester) async {
    await pumpForm(tester);
    await tester.enterText(find.byKey(const Key('product-price')), '10');
    await tester.enterText(find.byKey(const Key('product-cost')), '12');
    await tester.pump();
    expect(find.text('Note: selling price is below cost.'), findsOneWidget);
  });

  testWidgets('"No barcode" generates an internal code', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('No barcode: generate a code'));
    await tester.pump();
    expect(find.textContaining('TS-'), findsOneWidget);
  });
}
