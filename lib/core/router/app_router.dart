import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/core/router/route_guard.dart';
import 'package:tindascan/core/router/transitions.dart';
import 'package:tindascan/features/alerts/presentation/alerts_screen.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/auth/presentation/account_issue_screen.dart';
import 'package:tindascan/features/auth/presentation/connection_issue_screen.dart';
import 'package:tindascan/features/auth/presentation/login_screen.dart';
import 'package:tindascan/features/auth/presentation/profile_screen.dart';
import 'package:tindascan/features/auth/presentation/setup_owner_screen.dart';
import 'package:tindascan/features/auth/presentation/splash_screen.dart';
import 'package:tindascan/features/auth/presentation/staff_form_screen.dart';
import 'package:tindascan/features/auth/presentation/staff_list_screen.dart';
import 'package:tindascan/features/dashboard/presentation/dashboard_screen.dart';
import 'package:tindascan/features/home/presentation/app_shell.dart';
import 'package:tindascan/features/home/presentation/more_screen.dart';
import 'package:tindascan/features/products/presentation/product_detail_screen.dart';
import 'package:tindascan/features/products/presentation/product_form_screen.dart';
import 'package:tindascan/features/products/presentation/product_list_screen.dart';
import 'package:tindascan/features/reports/presentation/reports_screen.dart';
import 'package:tindascan/features/sales/presentation/receipt_screen.dart';
import 'package:tindascan/features/sales/presentation/sell_screen.dart';
import 'package:tindascan/features/scanner/presentation/scan_screen.dart';
import 'package:tindascan/features/settings/presentation/design_gallery_screen.dart';
import 'package:tindascan/features/settings/presentation/settings_screen.dart';
import 'package:tindascan/features/stock/presentation/movement_history_screen.dart';
import 'package:tindascan/features/stock/presentation/restock_list_screen.dart';
import 'package:tindascan/features/stock/presentation/stock_adjust_screen.dart';
import 'package:tindascan/shared/models/sale.dart';

/// Root navigator: full-screen routes (scanner, receipt, More sections)
/// render above the navigation shell.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The app router. It re-evaluates [RouteGuard.redirect] whenever the
/// session changes (sign-in, sign-out, deactivation, role change).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  String id(GoRouterState state) => state.pathParameters[AppRoutes.idParam]!;
  const idSegment = ':${AppRoutes.idParam}';

  GoRoute fullScreen(String path, Widget Function(GoRouterState) build) =>
      GoRoute(
        path: path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, state) => build(state),
      );

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) =>
        RouteGuard.redirect(ref.read(sessionProvider).value, state.uri.path),
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.setup,
        builder: (_, _) => const SetupOwnerScreen(),
      ),
      GoRoute(
        path: AppRoutes.connectionIssue,
        builder: (_, _) => const ConnectionIssueScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountIssue,
        builder: (_, _) => const AccountIssueScreen(),
      ),

      // Main sections inside the adaptive navigation shell. Branch order
      // must match `ShellBranch` in app_shell.dart.
      StatefulShellRoute(
        builder: (_, _, shell) => AppShell(shell: shell),
        navigatorContainerBuilder: (_, shell, children) => FadeBranchContainer(
          currentIndex: shell.currentIndex,
          children: children,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (_, _) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sell,
                builder: (_, _) => const SellScreen(),
                routes: [
                  GoRoute(
                    path: 'receipt',
                    parentNavigatorKey: rootNavigatorKey,
                    redirect: (_, state) =>
                        state.extra is Sale ? null : AppRoutes.sell,
                    pageBuilder: (_, state) => slideUpPage<void>(
                      key: state.pageKey,
                      child: ReceiptScreen(sale: state.extra! as Sale),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.products,
                builder: (_, _) => const ProductListScreen(),
                routes: [
                  // Must come before ':id' so "new" is not treated as an id.
                  GoRoute(
                    path: 'new',
                    builder: (_, state) => ProductFormScreen(
                      initialBarcode:
                          state.uri.queryParameters[AppRoutes.barcodeParam],
                    ),
                  ),
                  GoRoute(
                    path: idSegment,
                    builder: (_, state) =>
                        ProductDetailScreen(productId: id(state)),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (_, state) =>
                            ProductFormScreen(productId: id(state)),
                      ),
                      GoRoute(
                        path: 'stock',
                        builder: (_, state) =>
                            StockAdjustScreen(productId: id(state)),
                      ),
                      GoRoute(
                        path: 'history',
                        builder: (_, state) =>
                            MovementHistoryScreen(productId: id(state)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (_, _) => const MoreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Full-screen routes above the shell.
      GoRoute(
        path: AppRoutes.scan,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, state) =>
            slideUpPage<String>(key: state.pageKey, child: const ScanScreen()),
      ),
      fullScreen(AppRoutes.stock, (_) => const RestockListScreen()),
      fullScreen(AppRoutes.alerts, (_) => const AlertsScreen()),
      fullScreen(AppRoutes.reports, (_) => const ReportsScreen()),
      fullScreen(AppRoutes.settings, (_) => const SettingsScreen()),
      fullScreen(AppRoutes.staff, (_) => const StaffListScreen()),
      fullScreen(AppRoutes.staffNew, (_) => const StaffFormScreen()),
      if (kDebugMode)
        fullScreen(AppRoutes.designGallery, (_) => const DesignGalleryScreen()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
