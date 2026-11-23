import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tindascan/core/connectivity/connectivity_providers.dart';
import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/services/local_prefs.dart';
import 'package:tindascan/core/theme/app_theme.dart';
import 'package:tindascan/features/alerts/data/notification_service.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/providers/firebase_providers.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

import 'mocks.dart';

/// Records notifications instead of showing them.
class FakeAlertNotifier implements AlertNotifier {
  final List<List<Product>> shown = [];

  @override
  Future<void> showLowStock(
    List<Product> products,
    AppLocalizations l10n,
  ) async => shown.add(products);
}

/// Writes the setup flag and a user profile to [db].
Future<void> seedStore(FakeFirebaseFirestore db, AppUser user) async {
  await db.collection(FirestorePaths.settings).doc(FirestorePaths.setupDoc).set(
    {SettingsFields.completed: true},
  );
  await db
      .collection(FirestorePaths.settings)
      .doc(FirestorePaths.storeDoc)
      .set({
        SettingsFields.storeName: 'Aling Nena Store',
        SettingsFields.defaultLowStockThreshold: 5,
      });
  await db.collection(FirestorePaths.users).doc(user.uid).set({
    ...user.toMap(),
    UserFields.createdAt: DateTime.utc(2026),
  });
}

/// Overrides that run the whole app on a fake Firestore with [user] signed in.
List<Override> fakeBackendOverrides({
  required FakeFirebaseFirestore db,
  required AppUser user,
  bool online = true,
  AlertNotifier? notifier,
}) {
  final auth = MockAuthRepository();
  when(auth.uidChanges).thenAnswer((_) => Stream.value(user.uid));
  when(() => auth.currentUid).thenReturn(user.uid);
  when(auth.signOut).thenAnswer((_) async {});
  return [
    firestoreProvider.overrideWithValue(db),
    authRepositoryProvider.overrideWithValue(auth),
    connectivityStreamProvider.overrideWithValue(Stream.value(online)),
    localPrefsProvider.overrideWithValue(MemoryLocalPrefs()),
    alertNotifierProvider.overrideWithValue(notifier ?? FakeAlertNotifier()),
  ];
}

/// Pumps a localized router app around [routes].
Future<void> pumpRouterApp(
  WidgetTester tester, {
  required List<RouteBase> routes,
  required String initialLocation,
  List<Override> overrides = const [],
}) => tester.pumpWidget(
  ProviderScope(
    overrides: overrides,
    retry: (_, _) => null,
    child: MaterialApp.router(
      theme: AppTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(initialLocation: initialLocation, routes: routes),
    ),
  ),
);

/// Pumps frames until [finder] matches (avoids pumpAndSettle hanging on
/// progress indicators). Fails after [maxPumps].
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 100,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

/// Lets a state change render and its animations (count-ups, sheets,
/// snackbars) run to completion: one frame to start, then [duration].
Future<void> settle(
  WidgetTester tester, [
  Duration duration = const Duration(milliseconds: 700),
]) async {
  await tester.pump();
  await tester.pump(duration);
}
