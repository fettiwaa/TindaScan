import 'dart:math';

/// Generates codes for products without a printed barcode, e.g. loose
/// items sold by piece (`TS-LQ3K9Z-7F2A`). The `TS-` prefix can never clash
/// with numeric EAN/UPC barcodes, and the code satisfies the rules pattern
/// `^[A-Za-z0-9-]{1,64}$`. Uniqueness is still enforced by the
/// `barcodes/{code}` document created in the same transaction.
abstract final class InternalCode {
  static const String prefix = 'TS-';
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int _randomLength = 4;

  static String generate({DateTime? now, Random? random}) {
    final rng = random ?? Random.secure();
    final time = (now ?? DateTime.now()).millisecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase();
    final suffix = List.generate(
      _randomLength,
      (_) => _alphabet[rng.nextInt(_alphabet.length)],
    ).join();
    return '$prefix$time-$suffix';
  }

  static bool isInternal(String code) => code.startsWith(prefix);
}
