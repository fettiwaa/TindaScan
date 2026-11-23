import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/services/local_prefs.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/features/alerts/application/alert_providers.dart';
import 'package:tindascan/features/alerts/data/notification_service.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/products/data/firestore_product_repository.dart';
import 'package:tindascan/shared/providers/firebase_providers.dart';

import '../../helpers/fixtures.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_app.dart';

void main() {
  test('notifies each low-stock product at most once per day', () async {
    final db = FakeFirebaseFirestore();
    await FirestoreProductRepository(
      db,
    ).createProduct(product(stock: 1, threshold: 5), by: testOwner);
    await FirestoreProductRepository(db).createProduct(
      product(barcode: '999999', name: 'Plenty', stock: 50),
      by: testOwner,
    );
    final notifier = FakeAlertNotifier();
    final prefs = MemoryLocalPrefs();
    var now = DateTime.utc(2026, 11, 19, 2);

    ProviderContainer make() {
      final c = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          currentUserProvider.overrideWithValue(testOwner),
          alertNotifierProvider.overrideWithValue(notifier),
          localPrefsProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => now),
        ],
        retry: (_, _) => null,
      );
      addTearDown(c.dispose);
      return c;
    }

    expect(await make().read(lowStockNotificationProvider.future), 1);
    expect(notifier.shown.single.single.name, 'Lucky Me Pancit Canton');

    // Same day, new app session: nothing new.
    expect(await make().read(lowStockNotificationProvider.future), 0);

    // Next Manila day: notified again.
    now = now.add(const Duration(days: 1));
    expect(await make().read(lowStockNotificationProvider.future), 1);
    expect(notifier.shown, hasLength(2));
  });

  test('staff never trigger notifications', () async {
    final notifier = FakeAlertNotifier();
    final c = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        currentUserProvider.overrideWithValue(testStaff),
        alertNotifierProvider.overrideWithValue(notifier),
      ],
    );
    addTearDown(c.dispose);
    expect(await c.read(lowStockNotificationProvider.future), 0);
    expect(notifier.shown, isEmpty);
  });
}
