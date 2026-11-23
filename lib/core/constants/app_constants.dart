/// App-wide limits and tunables. Mirror the validation limits in
/// `firebase/firestore.rules` so client and server agree.
abstract final class AppConstants {
  static const String appName = 'TindaScan';
  static const String currencySymbol = '₱';

  // Validation limits (also enforced by security rules).
  static const int minPasswordLength = 8;
  static const int maxNameLength = 80;
  static const int maxEmailLength = 120;
  static const int maxStoreNameLength = 60;
  static const int maxNoteLength = 200;
  static const int defaultLowStockThreshold = 5;
  static const int maxLowStockThreshold = 10000;
  static const int maxBarcodeLength = 64;
  static const int maxCategoryLength = 40;

  /// Largest quantity accepted for one cart line or one stock adjustment.
  static const int maxQuantity = 9999;

  /// Most distinct products in one sale (rules allow up to 100 lines; a
  /// Firestore transaction must also stay under 500 writes).
  static const int maxCartLines = 100;

  // Performance / cost control.
  static const Duration searchDebounce = Duration(milliseconds: 350);
  static const int defaultPageSize = 20;

  /// Results shown in the Sell screen's search dropdown.
  static const int searchSuggestionLimit = 8;

  /// Upper bounds for report queries so one export cannot burn the free
  /// tier's 50k daily reads.
  static const int maxReportSales = 1000;
  static const int maxReportMovements = 1000;
  static const int maxReportProducts = 2000;
  static const int maxReportDays = 366;

  /// Low-stock and expiry lists are capped; a single store rarely has more.
  static const int maxAlertItems = 100;

  // Alerts.
  static const int expiryWarningDays = 7;

  /// Suggested restock brings stock up to `threshold * multiplier`.
  static const int restockTargetMultiplier = 2;

  // Scanner.
  /// Ignore the same barcode for this long (prevents double-adds).
  static const Duration scanDebounce = Duration(milliseconds: 1500);

  // Dashboard.
  static const int topSellerCount = 5;
  static const int stockChartItemCount = 5;

  /// The staff list is small for a single sari-sari store; capping the query
  /// keeps the read cost bounded even if someone creates many accounts.
  static const int maxStaffListSize = 50;

  /// Name of the secondary FirebaseApp used to create staff accounts without
  /// signing the owner out of the primary app.
  static const String staffCreatorAppName = 'tindascan-staff-creator';
}
