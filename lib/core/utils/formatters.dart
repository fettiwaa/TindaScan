import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:tindascan/core/utils/manila_time.dart';

/// Locale-aware date formatting. Times are shown in Asia/Manila.
abstract final class AppFormat {
  static String _locale(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.localeExists(locale) ? locale : 'en';
  }

  /// e.g. "Nov 19, 2026".
  static String date(BuildContext context, DateTime instant) =>
      DateFormat.yMMMd(_locale(context)).format(ManilaTime.wallClock(instant));

  /// e.g. "Nov 19, 2026 3:05 PM".
  static String dateTime(BuildContext context, DateTime instant) =>
      DateFormat.yMMMd(
        _locale(context),
      ).add_jm().format(ManilaTime.wallClock(instant));

  /// Short label for chart axes, e.g. "11/19".
  static String shortDay(String dayKey) =>
      '${int.parse(dayKey.substring(4, 6))}/${int.parse(dayKey.substring(6, 8))}';

  /// Date of a `yyyyMMdd` key, e.g. "Nov 19, 2026".
  static String dayKey(BuildContext context, String key) =>
      date(context, ManilaTime.parseDayKey(key));
}
