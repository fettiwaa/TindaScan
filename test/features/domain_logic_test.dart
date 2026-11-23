import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/features/dashboard/domain/stats_aggregation.dart';
import 'package:tindascan/features/products/domain/internal_code.dart';
import 'package:tindascan/features/products/domain/product_category.dart';
import 'package:tindascan/features/products/domain/product_query.dart';
import 'package:tindascan/features/products/domain/product_validators.dart';
import 'package:tindascan/features/scanner/domain/scan_debouncer.dart';
import 'package:tindascan/features/stock/domain/restock.dart';
import 'package:tindascan/shared/models/daily_stats.dart';
import 'package:tindascan/shared/models/product.dart';

import '../helpers/fixtures.dart';

DailyStats day(
  String key,
  int sales, {
  int cost = 0,
  int tx = 1,
  List<ProductDayStat> products = const [],
}) => DailyStats(
  dayKey: key,
  salesCentavos: sales,
  costCentavos: cost,
  transactionCount: tx,
  itemsSold: tx,
  products: products,
);

void main() {
  group('ScanDebouncer', () {
    test('drops repeats of the same code within the window', () {
      final d = ScanDebouncer(const Duration(milliseconds: 1500));
      final t0 = DateTime(2026);
      expect(d.accept('123', t0), isTrue);
      expect(
        d.accept('123', t0.add(const Duration(milliseconds: 500))),
        isFalse,
      );
      expect(
        d.accept('456', t0.add(const Duration(milliseconds: 600))),
        isTrue,
      );
      expect(d.accept('456', t0.add(const Duration(seconds: 3))), isTrue);
    });
  });

  group('StatsAggregation', () {
    final days = [
      day(
        '20261116',
        1000,
        cost: 700,
        products: const [
          ProductDayStat(productId: 'a', name: 'A', qty: 2, salesCentavos: 400),
          ProductDayStat(productId: 'b', name: 'B', qty: 5, salesCentavos: 600),
        ],
      ),
      day(
        '20261117',
        2000,
        cost: 1500,
        products: const [
          ProductDayStat(productId: 'a', name: 'A', qty: 4, salesCentavos: 800),
        ],
      ),
      day('20261124', 500, cost: 300),
    ];

    test('summarize totals and profit', () {
      final s = StatsAggregation.summarize(days);
      expect(s.salesCentavos, 3500);
      expect(s.profitCentavos, 1000);
      expect(s.transactionCount, 3);
    });

    test('topSellers aggregates across days by quantity', () {
      final top = StatsAggregation.topSellers(days, limit: 1);
      expect(top.single.productId, 'a');
      expect(top.single.qty, 6);
      expect(top.single.salesCentavos, 1200);
    });

    test('group by week starts on Monday', () {
      final rows = StatsAggregation.group(days, ReportGrouping.weekly);
      expect(rows, hasLength(2));
      expect(rows.first.startKey, '20261116');
      expect(rows.first.endKey, '20261117');
      expect(rows.first.summary.salesCentavos, 3000);
      expect(
        StatsAggregation.groupKey('20261122', ReportGrouping.weekly),
        '20261116',
      );
    });

    test('group by month and day', () {
      expect(
        StatsAggregation.group(days, ReportGrouping.monthly),
        hasLength(1),
      );
      expect(StatsAggregation.group(days, ReportGrouping.daily), hasLength(3));
    });
  });

  group('Restock', () {
    test('suggests quantities to reach threshold x multiplier', () {
      final list = Restock.suggestions([
        product(id: 'a', stock: 1, threshold: 5),
        product(id: 'b', stock: 9, threshold: 5),
        product(id: 'c', stock: 0, threshold: 0),
      ]);
      expect(list.map((s) => s.product.id), ['a', 'c']);
      expect(list.first.qtyNeeded, 9);
      expect(list.last.targetQty, 1);
    });

    test('StockAdjustment converts input to signed changes', () {
      expect(
        StockAdjustment.qtyChange(
          mode: AdjustmentMode.restock,
          input: 5,
          currentStock: 2,
        ),
        5,
      );
      expect(
        StockAdjustment.qtyChange(
          mode: AdjustmentMode.spoilage,
          input: 2,
          currentStock: 2,
        ),
        -2,
      );
      expect(
        StockAdjustment.qtyChange(
          mode: AdjustmentMode.correction,
          input: 7,
          currentStock: 10,
        ),
        -3,
      );
    });
  });

  group('Product', () {
    test('keywords allow searching any word prefix', () {
      final p = product();
      final map = p.toMap();
      expect(map['nameLower'], 'lucky me pancit canton');
      expect(
        map['keywords'],
        containsAll(['l', 'lu', 'pan', 'pancit', 'canton']),
      );
      expect(map['lowStock'], isFalse);
      expect(p.matchesSearch('pan can'), isTrue);
      expect(p.matchesSearch('ancit'), isFalse);
      expect(Product.searchToken('  Pancit  canton'), 'pancit');
      expect(Product.searchToken('extraordinarily'), 'extraordin');
      expect(Product.searchToken('  '), isNull);
    });

    test('low stock, expiry and round-trip', () {
      final now = DateTime.utc(2026, 11, 19);
      final p = product(stock: 3, expiry: now.add(const Duration(days: 5)));
      expect(p.isLowStock, isTrue);
      expect(p.expiresWithin(now, 7), isTrue);
      expect(p.isExpired(now), isFalse);
      expect(Product.fromMap(p.id, p.toMap()), p);
    });
  });

  group('Product validators and helpers', () {
    test('barcode', () {
      expect(ProductValidators.barcode(''), ProductFieldError.required);
      expect(
        ProductValidators.barcode('48 00/1'),
        ProductFieldError.invalidBarcode,
      );
      expect(ProductValidators.barcode('TS-ABC-12'), isNull);
      expect(ProductValidators.normalizeBarcode(' 4800 0166 '), '48000166');
    });

    test('money and quantity', () {
      expect(ProductValidators.money('12.505'), ProductFieldError.invalidMoney);
      expect(ProductValidators.money('12.50'), isNull);
      expect(
        ProductValidators.quantity('-1'),
        ProductFieldError.invalidQuantity,
      );
      expect(
        ProductValidators.quantity('0', allowZero: false),
        ProductFieldError.invalidQuantity,
      );
      expect(ProductValidators.quantity('10'), isNull);
      expect(
        ProductValidators.threshold('20000'),
        ProductFieldError.invalidQuantity,
      );
    });

    test('internal codes are valid barcodes and recognizable', () {
      final code = InternalCode.generate(
        now: DateTime.utc(2026),
        random: Random(1),
      );
      expect(InternalCode.isInternal(code), isTrue);
      expect(ProductValidators.barcode(code), isNull);
    });

    test('query detects barcodes vs names', () {
      expect(
        const ProductQuery(search: '4800016644283').looksLikeBarcode,
        isTrue,
      );
      expect(const ProductQuery(search: 'pancit').looksLikeBarcode, isFalse);
      expect(const ProductQuery(search: 'TS-K3J9-AB').looksLikeBarcode, isTrue);
    });

    test('categories fall back to others', () {
      expect(ProductCategory.fromKey('noodles'), ProductCategory.noodles);
      expect(ProductCategory.fromKey('???'), ProductCategory.others);
    });
  });
}
