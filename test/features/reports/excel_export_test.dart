import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/l10n/gen/app_localizations_en.dart';
import 'package:tindascan/features/dashboard/domain/stats_aggregation.dart';
import 'package:tindascan/features/reports/domain/excel_export.dart';
import 'package:tindascan/features/reports/presentation/report_sheets.dart';

import '../../helpers/fixtures.dart';

/// Numeric value of a decoded cell (whole numbers decode as ints).
num? number(CellValue? value) => switch (value) {
  IntCellValue(:final value) => value,
  DoubleCellValue(:final value) => value,
  _ => null,
};

void main() {
  final sheets = ReportSheets(
    AppLocalizationsEn(),
    formatDate: (d) => d.toIso8601String(),
    formatDayKey: (k) => k,
  );

  test('builds a multi-sheet workbook with headers and totals', () {
    final spec = ExcelReportSpec([
      sheets.sales(const [
        PeriodRow(
          startKey: '20261118',
          endKey: '20261118',
          summary: SalesSummary(
            salesCentavos: 12345,
            costCentavos: 10000,
            transactionCount: 3,
            itemsSold: 7,
          ),
        ),
      ]),
      sheets.inventory([product(stock: 4)]),
    ]);

    final bytes = buildWorkbook(spec);
    final excel = Excel.decodeBytes(bytes);

    expect(excel.tables.keys, containsAll(['Sales', 'Inventory']));
    final sales = excel.tables['Sales']!;
    expect(sales.rows.first.first?.value.toString(), 'Period');
    expect(number(sales.rows[1][3]?.value), 123.45);
    // Totals row.
    expect(sales.rows.last.first?.value.toString(), 'Total');
    expect(number(sales.rows.last[1]?.value), 3);

    final inventory = excel.tables['Inventory']!;
    // 4 units x ₱12.50 cost = ₱50.00 stock value.
    expect(number(inventory.rows[1][6]?.value), 50);
  });

  test('stock value ignores negative stock', () {
    expect(ReportSheets.stockValue(product(stock: -3)), 0);
  });
}
