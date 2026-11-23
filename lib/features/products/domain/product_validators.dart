import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/utils/money.dart';

/// Validation errors for the product form (localized in the UI).
enum ProductFieldError {
  required,
  tooLong,
  invalidBarcode,
  invalidMoney,
  invalidQuantity,
  costAbovePrice,
}

/// Pure validators mirroring `firebase/firestore.rules`.
abstract final class ProductValidators {
  static final RegExp _barcodePattern = RegExp(r'^[A-Za-z0-9-]+$');

  static ProductFieldError? name(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return ProductFieldError.required;
    if (input.length > AppConstants.maxNameLength) {
      return ProductFieldError.tooLong;
    }
    return null;
  }

  static ProductFieldError? barcode(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return ProductFieldError.required;
    if (input.length > AppConstants.maxBarcodeLength) {
      return ProductFieldError.tooLong;
    }
    if (!_barcodePattern.hasMatch(input)) {
      return ProductFieldError.invalidBarcode;
    }
    return null;
  }

  static ProductFieldError? money(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return ProductFieldError.required;
    return Money.tryParse(input) == null
        ? ProductFieldError.invalidMoney
        : null;
  }

  /// A selling price below cost is allowed (promos) but flagged as a warning
  /// by the form; this validator only rejects malformed input.
  static ProductFieldError? quantity(String? value, {bool allowZero = true}) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return ProductFieldError.required;
    final parsed = int.tryParse(input);
    if (parsed == null ||
        parsed < (allowZero ? 0 : 1) ||
        parsed > AppConstants.maxQuantity) {
      return ProductFieldError.invalidQuantity;
    }
    return null;
  }

  static ProductFieldError? threshold(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return ProductFieldError.required;
    final parsed = int.tryParse(input);
    if (parsed == null ||
        parsed < 0 ||
        parsed > AppConstants.maxLowStockThreshold) {
      return ProductFieldError.invalidQuantity;
    }
    return null;
  }

  /// Normalizes a scanned/typed barcode (trims, removes inner spaces).
  static String normalizeBarcode(String raw) =>
      raw.trim().replaceAll(RegExp(r'\s+'), '');
}
