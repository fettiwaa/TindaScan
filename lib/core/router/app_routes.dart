/// Route paths. Use these constants everywhere instead of string literals.
abstract final class AppRoutes {
  // Public / transitional
  static const String splash = '/splash';
  static const String login = '/login';
  static const String setup = '/setup';
  static const String accountIssue = '/account-issue';
  static const String connectionIssue = '/connection-issue';

  // Shared (owner + staff)
  static const String home = '/';
  static const String profile = '/profile';
  static const String sell = '/sell';
  static const String sellReceipt = '/sell/receipt';
  static const String products = '/products';
  static const String scan = '/scan';

  // Owner only
  static const String staff = '/staff';
  static const String staffNew = '/staff/new';
  static const String productNew = '/products/new';

  /// Suggested restock list.
  static const String stock = '/stock';
  static const String alerts = '/alerts';
  static const String dashboard = '/dashboard';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String more = '/more';

  /// Debug-only component showcase.
  static const String designGallery = '/design-gallery';

  /// Query parameter prefilling the barcode on the new-product form.
  static const String barcodeParam = 'barcode';

  /// Path parameter name for product routes.
  static const String idParam = 'id';

  /// `/products/:id` — read-only detail (staff allowed).
  static String productDetail(String id) => '$products/$id';

  /// `/products/:id/edit` — owner only.
  static String productEdit(String id) => '$products/$id/edit';

  /// `/products/:id/stock` — owner only.
  static String productStock(String id) => '$products/$id/stock';

  /// `/products/:id/history` — owner only.
  static String productHistory(String id) => '$products/$id/history';

  /// Routes reachable while signed out or mid-setup.
  static const Set<String> unauthenticated = {
    splash,
    login,
    setup,
    accountIssue,
    connectionIssue,
  };
}
