/// Receipt number formats.
///
/// Online sales use a per-day counter (`counters/receipts_yyyyMMdd`)
/// incremented inside the sale transaction, so numbers are sequential and
/// collision-free across devices: `20261119-0001`.
///
/// Offline sales cannot read the counter, so they use the day plus a
/// fragment of the (random, collision-safe) sale id: `20261119-X3F9A2C`.
abstract final class ReceiptNumber {
  static const int _sequenceDigits = 4;
  static const int _offlineIdChars = 6;
  static const String _offlineMarker = 'X';

  static String online(String dayKey, int sequence) =>
      '$dayKey-${sequence.toString().padLeft(_sequenceDigits, '0')}';

  static String offline(String dayKey, String saleId) {
    final fragment = saleId.length > _offlineIdChars
        ? saleId.substring(0, _offlineIdChars)
        : saleId;
    return '$dayKey-$_offlineMarker${fragment.toUpperCase()}';
  }
}
