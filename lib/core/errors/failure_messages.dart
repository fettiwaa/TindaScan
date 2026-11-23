import 'package:tindascan/core/errors/error_mapper.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/core/l10n/gen/app_localizations.dart';

/// Localized, user-friendly text for any error.
extension FailureMessage on Object {
  String toUserMessage(AppLocalizations l10n) {
    final failure = mapError(this);
    return switch (failure) {
      NetworkUnavailable() => l10n.errorNetwork,
      PermissionDenied() => l10n.errorPermission,
      NotFoundFailure() => l10n.errorNotFound,
      ConflictFailure() => l10n.errorConflict,
      RateLimitFailure() => l10n.errorRateLimit,
      IndexNotReadyFailure() => l10n.errorIndexNotReady,
      SetupAlreadyCompletedFailure() => l10n.errorSetupDone,
      DuplicateBarcodeFailure(:final barcode) => l10n.errorDuplicateBarcode(
        barcode,
      ),
      InsufficientStock(:final productName, :final available) =>
        l10n.errorInsufficientStock(productName, available),
      ProductNotFound(:final productName?) => l10n.errorProductUnavailable(
        productName,
      ),
      ProductNotFound(:final barcode) => l10n.productNotFoundMessage(
        barcode ?? '',
      ),
      PriceChangedFailure(:final productName) => l10n.errorPriceChanged(
        productName,
      ),
      InvalidPayment() => l10n.errorInsufficientPayment,
      ExportFailure() => l10n.errorExport,
      AuthFailure(:final reason) => switch (reason) {
        AuthFailureReason.invalidCredentials => l10n.errorInvalidCredentials,
        AuthFailureReason.emailAlreadyInUse => l10n.errorEmailInUse,
        AuthFailureReason.weakPassword => l10n.errorWeakPassword,
        AuthFailureReason.invalidEmail => l10n.errorInvalidEmail,
        AuthFailureReason.accountDisabled => l10n.errorAccountDisabled,
        AuthFailureReason.requiresRecentLogin => l10n.errorRecentLogin,
      },
      UnknownFailure() => l10n.errorUnknown,
    };
  }
}
