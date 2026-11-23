import 'dart:ui';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/services/local_prefs.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/dashboard/domain/stats_aggregation.dart';
import 'package:tindascan/features/products/application/product_providers.dart';
import 'package:tindascan/features/products/data/firestore_product_repository.dart';
import 'package:tindascan/features/products/domain/product_category.dart';
import 'package:tindascan/features/products/domain/product_query.dart';
import 'package:tindascan/features/reports/application/report_providers.dart';
import 'package:tindascan/features/reports/domain/report_filter.dart';
import 'package:tindascan/features/settings/application/locale_provider.dart';
import 'package:tindascan/features/settings/application/settings_controller.dart';
import 'package:tindascan/features/settings/application/settings_providers.dart';
import 'package:tindascan/features/stock/application/stock_controllers.dart';
import 'package:tindascan/features/stock/domain/restock.dart';
import 'package:tindascan/shared/models/store_settings.dart';
import 'package:tindascan/shared/providers/firebase_providers.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreProductRepository repo;
  final now = DateTime.utc(2026, 11, 19, 3);

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreProductRepository(db);
  });

  ProviderContainer make({LocalPrefs? prefs}) {
    final c = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(db),
        currentUserProvider.overrideWithValue(testOwner),
        clockProvider.overrideWithValue(() => now),
        if (prefs != null) localPrefsProvider.overrideWithValue(prefs),
      ],
      retry: (_, _) => null,
    );
    addTearDown(c.dispose);
    return c;
  }

  group('ProductListController', () {
    test('loads pages, loads more and reacts to the query', () async {
      for (var i = 0; i < 25; i++) {
        await repo.createProduct(
          product(
            barcode: '20000$i',
            name: 'Item ${i.toString().padLeft(2, '0')}',
          ),
          by: testOwner,
        );
      }
      final c = make();
      c.listen(productListProvider, (_, _) {});
      final first = await c.read(productListProvider.future);
      expect(first.items, hasLength(20));
      expect(first.hasMore, isTrue);

      await c.read(productListProvider.notifier).loadMore();
      final more = c.read(productListProvider).value!;
      expect(more.items, hasLength(25));
      expect(more.hasMore, isFalse);

      c
          .read(productQueryProvider.notifier)
          .update(const ProductQuery(search: 'item 07'));
      final filtered = await c.read(productListProvider.future);
      expect(filtered.items.single.name, 'Item 07');
    });
  });

  group('ProductEditController', () {
    test('creates, updates and archives', () async {
      final c = make();
      c.listen(productEditControllerProvider, (_, _) {});
      final notifier = c.read(productEditControllerProvider.notifier);

      final id = await notifier.save(
        product(id: ''),
        initialStockNote: 'Initial',
      );
      expect(id, isNotNull);
      final created = (await repo.getProduct(id!))!;

      expect(await notifier.save(created.copyWith(name: 'Renamed')), id);
      expect((await repo.getProduct(id))!.name, 'Renamed');

      expect(await notifier.setActive(id, active: false), isTrue);
      expect((await repo.getProduct(id))!.isActive, isFalse);
    });

    test('reports a duplicate barcode as an error', () async {
      await repo.createProduct(product(), by: testOwner);
      final c = make();
      c.listen(productEditControllerProvider, (_, _) {});
      final id = await c
          .read(productEditControllerProvider.notifier)
          .save(product(id: ''));
      expect(id, isNull);
      expect(c.read(productEditControllerProvider).hasError, isTrue);
    });
  });

  group('Stock controllers', () {
    test('adjust and paginate movement history', () async {
      final id = await repo.createProduct(product(stock: 5), by: testOwner);
      final c = make();
      c.listen(stockAdjustControllerProvider, (_, _) {});
      final adjust = c.read(stockAdjustControllerProvider.notifier);
      for (final mode in [
        AdjustmentMode.restock,
        AdjustmentMode.spoilage,
        AdjustmentMode.correction,
      ]) {
        expect(
          await adjust.adjust(
            productId: id,
            mode: mode,
            qtyChange: mode == AdjustmentMode.spoilage ? -1 : 2,
            note: 'n',
          ),
          isTrue,
        );
      }
      expect(
        await adjust.adjust(
          productId: id,
          mode: AdjustmentMode.restock,
          qtyChange: 0,
          note: '',
        ),
        isFalse,
      );
      expect((await repo.getProduct(id))!.stockQty, 8);

      c.listen(movementHistoryProvider(id), (_, _) {});
      final history = await c.read(movementHistoryProvider(id).future);
      expect(history.items, hasLength(4)); // initial + 3 adjustments
      await c.read(movementHistoryProvider(id).notifier).loadMore();
      expect(c.read(movementHistoryProvider(id)).value!.items, hasLength(4));
    });
  });

  group('Reports', () {
    test('initial filter is the last 7 Manila days', () {
      final filter = ReportFilter.initial(now);
      expect(filter.dayCount, 7);
      expect(filter.dayKeys.last, '20261119');
      expect(filter.toExclusive, ManilaTime.endOfDay(now));
      final monthly = filter.copyWith(
        type: ReportType.inventory,
        grouping: ReportGrouping.monthly,
      );
      expect(monthly == filter, isFalse);
      expect(
        monthly.copyWith(
          type: ReportType.sales,
          grouping: ReportGrouping.daily,
        ),
        filter,
      );
    });

    test(
      'providers load stats, inventory and movements for the range',
      () async {
        await repo.createProduct(product(), by: testOwner);
        final c = make();
        c.listen(reportFilterProvider, (_, _) {});
        expect(await c.read(reportStatsProvider.future), hasLength(7));
        expect(await c.read(reportInventoryProvider.future), hasLength(1));
        c
            .read(reportFilterProvider.notifier)
            .update(
              ReportFilter(
                from: DateTime.utc(2000),
                to: ManilaTime.startOfDay(DateTime.now()),
              ),
            );
        expect(await c.read(reportMovementsProvider.future), hasLength(1));
      },
    );
  });

  group('Settings', () {
    test('saves store settings and seeds sample data', () async {
      final c = make();
      c.listen(settingsControllerProvider, (_, _) {});
      final notifier = c.read(settingsControllerProvider.notifier);
      expect(
        await notifier.save(
          const StoreSettings(
            storeName: 'Tindahan ni Aling Nena',
            defaultLowStockThreshold: 4,
          ),
        ),
        isTrue,
      );
      c.listen(storeSettingsProvider, (_, _) {});
      final settings = await c.read(storeSettingsProvider.future);
      expect(settings.storeName, 'Tindahan ni Aling Nena');
      expect(await notifier.seed(initialStockNote: 'x'), 20);
    });

    test('language choice is persisted', () async {
      final prefs = MemoryLocalPrefs();
      final c = make(prefs: prefs);
      expect(await c.read(localeProvider.future), isNull);
      await c.read(localeProvider.notifier).setLocale(const Locale('fil'));
      expect(await prefs.getString(PrefKeys.locale), 'fil');

      final next = make(prefs: prefs);
      expect(await next.read(localeProvider.future), const Locale('fil'));
    });
  });

  test('ProductQuery copyWith and equality', () {
    const q = ProductQuery(search: 'x', category: ProductCategory.dairy);
    expect(q.copyWith(clearCategory: true).category, isNull);
    expect(q.copyWith(lowStockOnly: true) == q, isFalse);
    expect(q.copyWith(), q);
    expect(q.hashCode, q.copyWith().hashCode);
  });
}
