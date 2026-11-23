/// Cash payment math. All values are integer centavos.
abstract final class Payment {
  /// Bills offered as quick-cash chips (in centavos): ₱50, ₱100, ₱200,
  /// ₱500, ₱1000.
  static const List<int> quickBills = [5000, 10000, 20000, 50000, 100000];

  /// Large totals round up to the next ₱1000.
  static const int largestBill = 100000;

  /// Change due, or `null` when [tenderedCentavos] does not cover the total.
  static int? change({
    required int totalCentavos,
    required int tenderedCentavos,
  }) {
    if (totalCentavos < 0 || tenderedCentavos < totalCentavos) return null;
    return tenderedCentavos - totalCentavos;
  }

  static bool isSufficient({
    required int totalCentavos,
    required int tenderedCentavos,
  }) =>
      change(
        totalCentavos: totalCentavos,
        tenderedCentavos: tenderedCentavos,
      ) !=
      null;

  /// Quick-cash chips: the exact total, then every bill in [quickBills]
  /// that covers it (e.g. total ₱37 → ₱37, ₱50, ₱100, ₱200, ₱500, ₱1000).
  /// Totals above ₱1000 get the next round ₱1000 instead.
  static List<int> quickAmounts(int totalCentavos) {
    if (totalCentavos <= 0) return const [];
    final amounts = <int>[
      totalCentavos,
      for (final bill in quickBills)
        if (bill > totalCentavos) bill,
    ];
    if (amounts.length == 1) {
      final rounded =
          ((totalCentavos + largestBill - 1) ~/ largestBill) * largestBill;
      if (rounded > totalCentavos) amounts.add(rounded);
    }
    return amounts;
  }
}
