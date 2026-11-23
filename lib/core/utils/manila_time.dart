import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable clock so time-dependent logic is testable.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Date helpers pinned to Asia/Manila regardless of the device time zone.
///
/// Asia/Manila is a fixed UTC+8 offset with no daylight saving time, so a
/// constant offset is exact and avoids shipping the full tz database.
///
/// Known risk: the *day key* for a sale is computed from the device clock
/// (stored timestamps use the server clock). A device with a badly wrong
/// clock could file a sale under the wrong `daily_stats` day; the owner can
/// still see the true server time on every sale record.
abstract final class ManilaTime {
  static const Duration offset = Duration(hours: 8);

  /// Wall-clock date/time in Manila for [instant] (returned as a UTC-flagged
  /// [DateTime] whose fields are the Manila wall-clock values).
  static DateTime wallClock(DateTime instant) => instant.toUtc().add(offset);

  /// `yyyyMMdd` key of the Manila calendar day containing [instant].
  static String dayKey(DateTime instant) {
    final w = wallClock(instant);
    return '${w.year.toString().padLeft(4, '0')}'
        '${_two(w.month)}${_two(w.day)}';
  }

  /// UTC instant of Manila midnight at the start of [instant]'s day.
  static DateTime startOfDay(DateTime instant) {
    final w = wallClock(instant);
    return DateTime.utc(w.year, w.month, w.day).subtract(offset);
  }

  /// UTC instant of the next Manila midnight after [instant].
  static DateTime endOfDay(DateTime instant) =>
      startOfDay(instant).add(const Duration(days: 1));

  /// Parses a `yyyyMMdd` key back to the UTC instant of that Manila midnight.
  static DateTime parseDayKey(String key) {
    final year = int.parse(key.substring(0, 4));
    final month = int.parse(key.substring(4, 6));
    final day = int.parse(key.substring(6, 8));
    return DateTime.utc(year, month, day).subtract(offset);
  }

  /// Day keys for the last [days] Manila days ending today, oldest first.
  static List<String> lastDayKeys(DateTime now, int days) {
    final today = startOfDay(now);
    return [
      for (var i = days - 1; i >= 0; i--)
        dayKey(today.subtract(Duration(days: i))),
    ];
  }

  /// Day keys from [from] to [to] inclusive (Manila days), oldest first.
  static List<String> dayKeysBetween(DateTime from, DateTime to) {
    final keys = <String>[];
    var cursor = startOfDay(from);
    final last = startOfDay(to);
    while (!cursor.isAfter(last)) {
      keys.add(dayKey(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    return keys;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
