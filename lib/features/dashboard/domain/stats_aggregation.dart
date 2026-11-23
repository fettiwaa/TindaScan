import 'package:flutter/foundation.dart';

import 'package:tindascan/shared/models/daily_stats.dart';

/// Totals over a set of days.
@immutable
class SalesSummary {
  const SalesSummary({
    this.salesCentavos = 0,
    this.costCentavos = 0,
    this.transactionCount = 0,
    this.itemsSold = 0,
  });

  final int salesCentavos;
  final int costCentavos;
  final int transactionCount;
  final int itemsSold;

  int get profitCentavos => salesCentavos - costCentavos;

  SalesSummary operator +(DailyStats day) => SalesSummary(
    salesCentavos: salesCentavos + day.salesCentavos,
    costCentavos: costCentavos + day.costCentavos,
    transactionCount: transactionCount + day.transactionCount,
    itemsSold: itemsSold + day.itemsSold,
  );

  @override
  bool operator ==(Object other) =>
      other is SalesSummary &&
      other.salesCentavos == salesCentavos &&
      other.costCentavos == costCentavos &&
      other.transactionCount == transactionCount &&
      other.itemsSold == itemsSold;

  @override
  int get hashCode =>
      Object.hash(salesCentavos, costCentavos, transactionCount, itemsSold);
}

/// Report period size.
enum ReportGrouping { daily, weekly, monthly }

/// One row of a grouped sales report.
@immutable
class PeriodRow {
  const PeriodRow({
    required this.startKey,
    required this.endKey,
    required this.summary,
  });

  /// First and last `yyyyMMdd` day included in this period.
  final String startKey;
  final String endKey;
  final SalesSummary summary;
}

/// Pure aggregation over `daily_stats` documents (unit-tested).
abstract final class StatsAggregation {
  static SalesSummary summarize(Iterable<DailyStats> days) =>
      days.fold(const SalesSummary(), (sum, day) => sum + day);

  /// Best-sellers by quantity (ties broken by sales amount), across days.
  static List<ProductDayStat> topSellers(
    Iterable<DailyStats> days, {
    int? limit,
  }) {
    final totals = <String, ProductDayStat>{};
    for (final day in days) {
      for (final p in day.products) {
        final prev = totals[p.productId];
        totals[p.productId] = ProductDayStat(
          productId: p.productId,
          name: p.name.isNotEmpty ? p.name : (prev?.name ?? ''),
          qty: (prev?.qty ?? 0) + p.qty,
          salesCentavos: (prev?.salesCentavos ?? 0) + p.salesCentavos,
        );
      }
    }
    final sorted = totals.values.toList()
      ..sort((a, b) {
        final byQty = b.qty.compareTo(a.qty);
        return byQty != 0 ? byQty : b.salesCentavos.compareTo(a.salesCentavos);
      });
    return limit == null ? sorted : sorted.take(limit).toList();
  }

  /// Groups days (oldest first) into daily/weekly/monthly rows.
  /// Weeks start on Monday.
  static List<PeriodRow> group(List<DailyStats> days, ReportGrouping grouping) {
    final rows = <PeriodRow>[];
    String? currentGroup;
    String? start;
    String? end;
    var summary = const SalesSummary();

    void flush() {
      final first = start;
      final last = end;
      if (first != null && last != null) {
        rows.add(PeriodRow(startKey: first, endKey: last, summary: summary));
      }
    }

    for (final day in days) {
      final group = groupKey(day.dayKey, grouping);
      if (group != currentGroup) {
        flush();
        currentGroup = group;
        start = day.dayKey;
        summary = const SalesSummary();
      }
      end = day.dayKey;
      summary = summary + day;
    }
    flush();
    return rows;
  }

  /// Identifier of the period containing [dayKey].
  static String groupKey(String dayKey, ReportGrouping grouping) {
    switch (grouping) {
      case ReportGrouping.daily:
        return dayKey;
      case ReportGrouping.monthly:
        return dayKey.substring(0, 6);
      case ReportGrouping.weekly:
        final date = DateTime.utc(
          int.parse(dayKey.substring(0, 4)),
          int.parse(dayKey.substring(4, 6)),
          int.parse(dayKey.substring(6, 8)),
        );
        final monday = date.subtract(Duration(days: date.weekday - 1));
        return '${monday.year.toString().padLeft(4, '0')}'
            '${monday.month.toString().padLeft(2, '0')}'
            '${monday.day.toString().padLeft(2, '0')}';
    }
  }
}
