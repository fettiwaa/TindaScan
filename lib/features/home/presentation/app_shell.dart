import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/features/alerts/application/alert_providers.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';

/// Shell branch indexes (see `app_router.dart`).
abstract final class ShellBranch {
  static const int dashboard = 0;
  static const int sell = 1;
  static const int products = 2;
  static const int more = 3;
  static const int profile = 4;
}

class _Destination {
  const _Destination(this.branch, this.icon, this.label, {this.badge = 0});

  final int branch;
  final IconData icon;
  final String label;
  final int badge;
}

/// Adaptive app frame: bottom NavigationBar on phones, NavigationRail on
/// tablets (extended on wide screens). Owners get Dashboard, Sell,
/// Products, More; staff get Sell, Products, Profile.
class AppShell extends ConsumerWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isOwner = ref.watch(
      currentUserProvider.select((u) => u?.isOwner ?? false),
    );
    // Owner only: low-stock badge and the once-a-day notification check.
    final lowStock = isOwner ? ref.watch(lowStockCountProvider).value ?? 0 : 0;
    if (isOwner) ref.watch(lowStockNotificationProvider);

    final destinations = isOwner
        ? [
            _Destination(
              ShellBranch.dashboard,
              Symbols.space_dashboard_rounded,
              l10n.menuDashboard,
            ),
            _Destination(
              ShellBranch.sell,
              Symbols.point_of_sale_rounded,
              l10n.menuSell,
            ),
            _Destination(
              ShellBranch.products,
              Symbols.inventory_2_rounded,
              l10n.menuProducts,
            ),
            _Destination(
              ShellBranch.more,
              Symbols.menu_rounded,
              l10n.navMore,
              badge: lowStock,
            ),
          ]
        : [
            _Destination(
              ShellBranch.sell,
              Symbols.point_of_sale_rounded,
              l10n.menuSell,
            ),
            _Destination(
              ShellBranch.products,
              Symbols.inventory_2_rounded,
              l10n.menuProducts,
            ),
            _Destination(
              ShellBranch.profile,
              Symbols.person_rounded,
              l10n.menuProfile,
            ),
          ];

    var selected = destinations.indexWhere(
      (d) => d.branch == shell.currentIndex,
    );
    // The owner reaches Profile from More, so keep More highlighted there.
    if (selected < 0) selected = destinations.length - 1;

    void onSelect(int index) {
      final branch = destinations[index].branch;
      // Tapping the current tab again returns to its first screen.
      shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
      if (isOwner) ref.invalidate(lowStockCountProvider);
    }

    Widget icon(_Destination d, {required bool filled}) {
      final glyph = Icon(d.icon, fill: filled ? 1 : 0);
      return d.badge > 0 ? Badge.count(count: d.badge, child: glyph) : glyph;
    }

    final size = context.windowSize;
    if (size == WindowSize.compact) {
      return Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          key: const Key('app-navigation-bar'),
          selectedIndex: selected,
          onDestinationSelected: onSelect,
          animationDuration: context.motion.normal,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                key: Key('nav-${d.branch}'),
                icon: icon(d, filled: false),
                selectedIcon: icon(d, filled: true),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extended = size == WindowSize.expanded;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              key: const Key('app-navigation-rail'),
              selectedIndex: selected,
              onDestinationSelected: onSelect,
              extended: extended,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              groupAlignment: -0.85,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: icon(d, filled: false),
                    selectedIcon: icon(d, filled: true),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      ),
    );
  }
}
