/// Typed, expected failures surfaced to the UI.
///
/// Repositories translate platform exceptions (FirebaseException, etc.) into
/// one of these via `mapError`, so the presentation layer never inspects
/// Firebase error codes and can show a friendly, localized message.
sealed class Failure implements Exception {
  const Failure();
}

/// No connection, or the backend is unreachable.
final class NetworkUnavailable extends Failure {
  const NetworkUnavailable();
}

/// The security rules rejected the operation.
final class PermissionDenied extends Failure {
  const PermissionDenied();
}

/// The requested document does not exist.
final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

/// Data changed concurrently (e.g. transaction contention); retry may work.
final class ConflictFailure extends Failure {
  const ConflictFailure();
}

/// A query needs a Firestore index that is missing or still building
/// (typically for a few minutes right after `firebase deploy`).
final class IndexNotReadyFailure extends Failure {
  const IndexNotReadyFailure();
}

/// Too many attempts; the backend is throttling this client.
final class RateLimitFailure extends Failure {
  const RateLimitFailure();
}

/// Authentication-specific failure reasons.
enum AuthFailureReason {
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  accountDisabled,
  requiresRecentLogin,
}

/// Sign-in / sign-up failures.
final class AuthFailure extends Failure {
  const AuthFailure(this.reason);
  final AuthFailureReason reason;
}

/// The one-time owner setup has already been completed.
final class SetupAlreadyCompletedFailure extends Failure {
  const SetupAlreadyCompletedFailure();
}

/// A product barcode already belongs to another product.
final class DuplicateBarcodeFailure extends Failure {
  const DuplicateBarcodeFailure(this.barcode);
  final String barcode;
}

/// Not enough stock to complete a sale or adjustment.
final class InsufficientStock extends Failure {
  const InsufficientStock({required this.productName, required this.available});
  final String productName;
  final int available;
}

/// No active product matches a scanned barcode ([barcode] set), or a product
/// in the cart was archived since it was added ([productName] set).
final class ProductNotFound extends Failure {
  const ProductNotFound({this.barcode, this.productName});
  final String? barcode;
  final String? productName;
}

/// A price changed on another device after the item was added to the cart.
/// The cart is refreshed and the cashier confirms the new total.
final class PriceChangedFailure extends Failure {
  const PriceChangedFailure(this.productName);
  final String productName;
}

/// Amount tendered is less than the total.
final class InvalidPayment extends Failure {
  const InvalidPayment();
}

/// The report file could not be generated or shared.
final class ExportFailure extends Failure {
  const ExportFailure();
}

/// Anything not anticipated. Details are logged (without personal data).
final class UnknownFailure extends Failure {
  const UnknownFailure([this.debugCode]);

  /// Non-sensitive error code for logs/support (never shown verbatim).
  final String? debugCode;
}
