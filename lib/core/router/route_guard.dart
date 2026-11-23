import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/features/auth/domain/session.dart';
import 'package:tindascan/shared/models/user_role.dart';

/// Pure, unit-testable routing policy.
///
/// The router is a UX guard only; the real enforcement is in
/// `firebase/firestore.rules`, so a tampered client still cannot read reports
/// or edit prices.
abstract final class RouteGuard {
  /// Path prefixes staff may open (each also matches its sub-paths).
  static const List<String> _staffPrefixes = [
    AppRoutes.sell,
    AppRoutes.products,
    AppRoutes.profile,
    AppRoutes.scan,
  ];

  /// Sub-paths under staff prefixes that are still owner-only.
  static final List<RegExp> _ownerOnlyPatterns = [
    RegExp('^${AppRoutes.productNew}\$'),
    RegExp('^${AppRoutes.products}/[^/]+/(edit|history|stock)\$'),
  ];

  /// First screen after sign-in: Dashboard for owners, Sell for staff.
  static String landingFor(UserRole role) =>
      role.isOwner ? AppRoutes.dashboard : AppRoutes.sell;

  /// Whether [role] may open [location].
  static bool canAccess(UserRole role, String location) {
    if (role.isOwner) return true;
    final path = Uri.parse(location).path;
    if (path == AppRoutes.home) return true;
    if (_ownerOnlyPatterns.any((pattern) => pattern.hasMatch(path))) {
      return false;
    }
    return _staffPrefixes.any(
      (prefix) => path == prefix || path.startsWith('$prefix/'),
    );
  }

  /// Returns the path to redirect to, or `null` to stay on [location].
  static String? redirect(Session? session, String location) {
    final path = Uri.parse(location).path;
    String? goTo(String target) => path == target ? null : target;

    return switch (session) {
      null || SessionLoading() => goTo(AppRoutes.splash),
      SessionSetupCheckFailed() => goTo(AppRoutes.connectionIssue),
      SessionSignedOut(setupCompleted: false) => goTo(AppRoutes.setup),
      SessionSignedOut() => goTo(AppRoutes.login),
      SessionMissingProfile(setupCompleted: false) => goTo(AppRoutes.setup),
      SessionMissingProfile() => goTo(AppRoutes.accountIssue),
      SessionSignedIn(:final user) =>
        path == AppRoutes.home ||
                AppRoutes.unauthenticated.contains(path) ||
                !canAccess(user.role, path)
            ? landingFor(user.role)
            : null,
    };
  }
}
