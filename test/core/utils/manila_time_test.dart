import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/utils/manila_time.dart';

void main() {
  group('ManilaTime', () {
    test('day key uses Manila (UTC+8), not UTC', () {
      // 2026-11-18 17:30 UTC == 2026-11-19 01:30 Manila.
      expect(ManilaTime.dayKey(DateTime.utc(2026, 11, 18, 17, 30)), '20261119');
      // 2026-11-18 15:59 UTC == 2026-11-18 23:59 Manila.
      expect(ManilaTime.dayKey(DateTime.utc(2026, 11, 18, 15, 59)), '20261118');
    });

    test('start and end of day are Manila midnights in UTC', () {
      final instant = DateTime.utc(2026, 11, 19, 3);
      expect(ManilaTime.startOfDay(instant), DateTime.utc(2026, 11, 18, 16));
      expect(ManilaTime.endOfDay(instant), DateTime.utc(2026, 11, 19, 16));
    });

    test('parseDayKey round-trips', () {
      final start = ManilaTime.parseDayKey('20260301');
      expect(start, DateTime.utc(2026, 2, 28, 16));
      expect(ManilaTime.dayKey(start), '20260301');
    });

    test('lastDayKeys returns oldest first, ending today', () {
      final keys = ManilaTime.lastDayKeys(DateTime.utc(2026, 3, 1, 2), 3);
      expect(keys, ['20260227', '20260228', '20260301']);
    });

    test('dayKeysBetween is inclusive', () {
      final keys = ManilaTime.dayKeysBetween(
        DateTime.utc(2026, 12, 30, 4),
        DateTime.utc(2027, 1, 1, 4),
      );
      expect(keys, ['20261230', '20261231', '20270101']);
    });
  });
}
