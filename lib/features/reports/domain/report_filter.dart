import 'package:flutter/foundation.dart';

import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/features/dashboard/domain/stats_aggregation.dart';

/// Which report is shown.
enum ReportType { sales, bestSellers, inventory, movements }

/// Report selection: inclusive Manila-day range, type and grouping.
@immutable
class ReportFilter {
  const ReportFilter({
    required this.from,
    required this.to,
    this.type = ReportType.sales,
    this.grouping = ReportGrouping.daily,
  });

  /// The current week so far (last 7 days including today).
  factory ReportFilter.initial(DateTime now) => ReportFilter(
    from: ManilaTime.startOfDay(now.subtract(const Duration(days: 6))),
    to: ManilaTime.startOfDay(now),
  );

  /// UTC instant of the first day's Manila midnight.
  final DateTime from;

  /// UTC instant of the last day's Manila midnight (inclusive day).
  final DateTime to;
  final ReportType type;
  final ReportGrouping grouping;

  /// Exclusive end instant for timestamp queries.
  DateTime get toExclusive => ManilaTime.endOfDay(to);

  List<String> get dayKeys => ManilaTime.dayKeysBetween(from, to);

  int get dayCount => dayKeys.length;

  ReportFilter copyWith({
    DateTime? from,
    DateTime? to,
    ReportType? type,
    ReportGrouping? grouping,
  }) => ReportFilter(
    from: from ?? this.from,
    to: to ?? this.to,
    type: type ?? this.type,
    grouping: grouping ?? this.grouping,
  );

  @override
  bool operator ==(Object other) =>
      other is ReportFilter &&
      other.from == from &&
      other.to == to &&
      other.type == type &&
      other.grouping == grouping;

  @override
  int get hashCode => Object.hash(from, to, type, grouping);
}
