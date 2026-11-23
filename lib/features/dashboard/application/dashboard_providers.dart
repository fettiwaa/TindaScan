import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/shared/models/daily_stats.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// Chart range in days (7 or 30).
class DashboardRange extends Notifier<int> {
  static const int week = 7;
  static const int month = 30;

  @override
  int build() => week;

  // ignore: use_setters_to_change_properties
  void set(int days) => state = days;
}

final dashboardRangeProvider = NotifierProvider<DashboardRange, int>(
  DashboardRange.new,
);

/// Daily stats for the selected range, oldest first (today is last).
/// Read cost: 7 or 30 small documents, regardless of sales volume.
final dashboardStatsProvider = FutureProvider.autoDispose<List<DailyStats>>((
  ref,
) {
  final days = ref.watch(dashboardRangeProvider);
  final now = ref.watch(clockProvider)();
  return ref
      .watch(statsRepositoryProvider)
      .fetchDays(ManilaTime.lastDayKeys(now, days));
});

/// Products with the lowest stock (stock overview chart).
final lowestStockProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) => ref
      .watch(productRepositoryProvider)
      .lowestStock(limit: AppConstants.stockChartItemCount),
);
