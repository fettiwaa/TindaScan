import 'package:tindascan/shared/models/daily_stats.dart';

/// Daily aggregates (owner only). Throws `Failure` on error.
abstract interface class StatsRepository {
  /// Stats for the given `yyyyMMdd` keys, in the same order. Missing days
  /// are returned as empty stats. Read cost: one read per key.
  Future<List<DailyStats>> fetchDays(List<String> dayKeys);
}
