import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/features/dashboard/domain/stats_aggregation.dart';
import 'package:tindascan/features/products/domain/product_category.dart';
import 'package:tindascan/features/products/presentation/product_labels.dart';
import 'package:tindascan/features/reports/domain/excel_export.dart';
import 'package:tindascan/features/stock/presentation/movement_labels.dart';
import 'package:tindascan/shared/models/daily_stats.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/models/sale.dart';
import 'package:tindascan/shared/models/stock_movement.dart';

/// Builds localized worksheet specs from report data.
class ReportSheets {
  const ReportSheets(
    this.l10n, {
    required this.formatDate,
    required this.formatDayKey,
  });

  final AppLocalizations l10n;
  final String Function(DateTime) formatDate;
  final String Function(String) formatDayKey;

  String periodLabel(PeriodRow row) => row.startKey == row.endKey
      ? formatDayKey(row.startKey)
      : '${formatDayKey(row.startKey)} – ${formatDayKey(row.endKey)}';

  ExcelSheetSpec sales(List<PeriodRow> rows) {
    final total = rows.fold(
      const SalesSummary(),
      (sum, r) => SalesSummary(
        salesCentavos: sum.salesCentavos + r.summary.salesCentavos,
        costCentavos: sum.costCentavos + r.summary.costCentavos,
        transactionCount: sum.transactionCount + r.summary.transactionCount,
        itemsSold: sum.itemsSold + r.summary.itemsSold,
      ),
    );
    List<Object?> line(String label, SalesSummary s) => [
      label,
      s.transactionCount,
      s.itemsSold,
      s.salesCentavos,
      s.costCentavos,
      s.profitCentavos,
    ];
    return ExcelSheetSpec(
      name: l10n.reportsSales,
      headers: [
        l10n.reportsPeriodCol,
        l10n.reportsTransactionsCol,
        l10n.reportsItemsCol,
        l10n.reportsSalesCol,
        l10n.reportsCostCol,
        l10n.reportsProfitCol,
      ],
      kinds: const [
        CellKind.text,
        CellKind.integer,
        CellKind.integer,
        CellKind.money,
        CellKind.money,
        CellKind.money,
      ],
      rows: [for (final r in rows) line(periodLabel(r), r.summary)],
      totals: line(l10n.reportsTotalRow, total),
    );
  }

  ExcelSheetSpec transactions(List<Sale> sales) => ExcelSheetSpec(
    name: l10n.reportsTransactionsSheet,
    headers: [
      l10n.reportsDateCol,
      l10n.reportsReceiptCol,
      l10n.reportsCashierCol,
      l10n.reportsItemsCol,
      l10n.reportsSalesCol,
      l10n.reportsCostCol,
      l10n.reportsProfitCol,
    ],
    kinds: const [
      CellKind.text,
      CellKind.text,
      CellKind.text,
      CellKind.integer,
      CellKind.money,
      CellKind.money,
      CellKind.money,
    ],
    rows: [
      for (final s in sales)
        [
          s.createdAt == null ? '' : formatDate(s.createdAt!),
          s.receiptNo,
          s.cashierName,
          s.itemCount,
          s.totalCentavos,
          s.costTotalCentavos,
          s.profitCentavos,
        ],
    ],
    totals: [
      l10n.reportsTotalRow,
      '',
      '',
      sales.fold<int>(0, (sum, s) => sum + s.itemCount),
      sales.fold<int>(0, (sum, s) => sum + s.totalCentavos),
      sales.fold<int>(0, (sum, s) => sum + s.costTotalCentavos),
      sales.fold<int>(0, (sum, s) => sum + s.profitCentavos),
    ],
  );

  ExcelSheetSpec bestSellers(List<ProductDayStat> items) => ExcelSheetSpec(
    name: l10n.reportsBestSellers,
    headers: [
      '#',
      l10n.reportsProductCol,
      l10n.reportsQtyCol,
      l10n.reportsSalesCol,
    ],
    kinds: const [
      CellKind.integer,
      CellKind.text,
      CellKind.integer,
      CellKind.money,
    ],
    rows: [
      for (var i = 0; i < items.length; i++)
        [i + 1, items[i].name, items[i].qty, items[i].salesCentavos],
    ],
    totals: [
      null,
      l10n.reportsTotalRow,
      items.fold<int>(0, (sum, p) => sum + p.qty),
      items.fold<int>(0, (sum, p) => sum + p.salesCentavos),
    ],
  );

  ExcelSheetSpec inventory(List<Product> products) => ExcelSheetSpec(
    name: l10n.reportsInventory,
    headers: [
      l10n.reportsProductCol,
      l10n.reportsBarcodeCol,
      l10n.reportsCategoryCol,
      l10n.reportsPriceCol,
      l10n.reportsCostCol,
      l10n.reportsStockCol,
      l10n.reportsValueCol,
    ],
    kinds: const [
      CellKind.text,
      CellKind.text,
      CellKind.text,
      CellKind.money,
      CellKind.money,
      CellKind.integer,
      CellKind.money,
    ],
    rows: [
      for (final p in products)
        [
          p.name,
          p.barcode,
          ProductCategory.fromKey(p.category).label(l10n),
          p.unitPriceCentavos,
          p.costPriceCentavos,
          p.stockQty,
          stockValue(p),
        ],
    ],
    totals: [
      l10n.reportsTotalRow,
      '',
      '',
      null,
      null,
      products.fold<int>(0, (sum, p) => sum + p.stockQty),
      products.fold<int>(0, (sum, p) => sum + stockValue(p)),
    ],
  );

  ExcelSheetSpec movements(List<StockMovement> list) => ExcelSheetSpec(
    name: l10n.reportsMovements,
    headers: [
      l10n.reportsDateCol,
      l10n.reportsProductCol,
      l10n.reportsTypeCol,
      l10n.reportsChangeCol,
      l10n.reportsUserCol,
      l10n.reportsNoteCol,
    ],
    kinds: const [
      CellKind.text,
      CellKind.text,
      CellKind.text,
      CellKind.integer,
      CellKind.text,
      CellKind.text,
    ],
    rows: [
      for (final m in list)
        [
          m.createdAt == null ? '' : formatDate(m.createdAt!),
          m.productName,
          m.type.label(l10n),
          m.qtyChange,
          m.userName,
          m.note,
        ],
    ],
  );

  /// Value of stock on hand at cost (negative stock counts as zero).
  static int stockValue(Product p) =>
      (p.stockQty < 0 ? 0 : p.stockQty) * p.costPriceCentavos;
}
