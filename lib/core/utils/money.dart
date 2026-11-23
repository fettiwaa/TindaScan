import 'package:intl/intl.dart';

import 'package:tindascan/core/constants/app_constants.dart';

/// The single place where money is formatted and parsed.
///
/// All amounts in the app are integer **centavos** (₱1.00 == 100). Doubles
/// are never used for money, so totals and change are always exact.
abstract final class Money {
  static const int centavosPerPeso = 100;

  /// Largest amount the parser accepts (₱9,999,999.99) — far above any
  /// sari-sari transaction and well inside the 53-bit safe integer range.
  static const int maxCentavos = 999999999;

  static final NumberFormat _grouping = NumberFormat('#,##0', 'en_US');
  static final RegExp _inputPattern = RegExp(r'^\d{1,7}(\.\d{0,2})?$');

  /// Formats [centavos] as `₱1,234.50` (or `-₱5.00` for negatives).
  static String format(int centavos, {bool withSymbol = true}) {
    final isNegative = centavos < 0;
    final absolute = centavos.abs();
    final pesos = absolute ~/ centavosPerPeso;
    final cents = (absolute % centavosPerPeso).toString().padLeft(2, '0');
    final symbol = withSymbol ? AppConstants.currencySymbol : '';
    final body = '$symbol${_grouping.format(pesos)}.$cents';
    return isNegative ? '-$body' : body;
  }

  /// Formats centavos as a plain editable value, e.g. `12.50`.
  static String toInput(int centavos) =>
      format(centavos, withSymbol: false).replaceAll(',', '');

  /// Parses user input such as `12`, `12.5`, `1,234.50` or `₱20` into
  /// centavos. Returns `null` for invalid, negative or over-precise input.
  static int? tryParse(String input) {
    final cleaned = input
        .trim()
        .replaceAll(',', '')
        .replaceAll(AppConstants.currencySymbol, '');
    if (!_inputPattern.hasMatch(cleaned)) return null;
    final parts = cleaned.split('.');
    final pesos = int.parse(parts.first);
    final fraction = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
    final value = pesos * centavosPerPeso + int.parse(fraction);
    return value > maxCentavos ? null : value;
  }
}
