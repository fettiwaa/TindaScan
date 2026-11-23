import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/app.dart';
import 'package:tindascan/core/router/app_router.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/features/sales/data/firestore_sales_repository.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

/// Reports a fixed pending-writes state (the fake Firestore has none).
class _SalesRepo extends FirestoreSalesRepository {
  _SalesRepo(super.db, {required this.unsynced});

  final bool unsynced;

  @override
  Future<bool> hasUnsyncedSales({Duration wait = Duration.zero}) async =>
      unsynced;
}

void main() {
  Future<void> openProfileAndTapSignOut(
    WidgetTester tester, {
    required bool unsynced,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final db = FakeFirebaseFirestore();
    await seedStore(db, testStaff);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...fakeBackendOverrides(db: db, user: testStaff),
          salesRepositoryProvider.overrideWithValue(
            _SalesRepo(db, unsynced: unsynced),
          ),
        ],
        retry: (_, _) => null,
        child: const TindaScanApp(),
      ),
    );
    await pumpUntil(tester, find.byKey(const Key('app-navigation-bar')));
    ProviderScope.containerOf(
      tester.element(find.byType(TindaScanApp)),
    ).read(routerProvider).go(AppRoutes.profile);
    final signOut = find.text('Sign out').hitTestable();
    await pumpUntil(tester, signOut);
    await settle(tester, const Duration(seconds: 1));
    await tester.tap(signOut);
    await settle(tester, const Duration(seconds: 1));
  }

  testWidgets('warns before signing out with unsynced sales', (tester) async {
    await openProfileAndTapSignOut(tester, unsynced: true);
    expect(find.text("Some sales haven't synced yet"), findsOneWidget);
    expect(find.text('Sign out anyway'), findsOneWidget);
  });

  testWidgets('plain confirmation when everything is synced', (tester) async {
    await openProfileAndTapSignOut(tester, unsynced: false);
    expect(find.text('Sign out of TindaScan?'), findsOneWidget);
    expect(find.text("Some sales haven't synced yet"), findsNothing);
  });
}
