import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/app_card.dart';
import 'package:tindascan/core/widgets/motion.dart';
import 'package:tindascan/features/alerts/application/alert_providers.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/auth/presentation/auth_field_messages.dart';

/// Owner's "More" tab: the less frequent sections as clean list tiles.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final lowStock = ref.watch(lowStockCountProvider).value ?? 0;

    final groups = <(String, List<(IconData, String, String, int)>)>[
      (
        l10n.moreInventory,
        [
          (
            Symbols.notifications_rounded,
            l10n.menuAlerts,
            AppRoutes.alerts,
            lowStock,
          ),
          (
            Symbols.shopping_cart_checkout_rounded,
            l10n.menuRestock,
            AppRoutes.stock,
            0,
          ),
          (Symbols.table_chart_rounded, l10n.menuReports, AppRoutes.reports, 0),
        ],
      ),
      (
        l10n.moreStore,
        [
          (Symbols.group_rounded, l10n.menuStaff, AppRoutes.staff, 0),
          (Symbols.settings_rounded, l10n.menuSettings, AppRoutes.settings, 0),
          (Symbols.person_rounded, l10n.menuProfile, AppRoutes.profile, 0),
        ],
      ),
    ];

    var order = 0;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(l10n.navMore)),
          if (user != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
                child: Text(
                  '${user.name} · ${user.role.label(l10n)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          for (final (title, items) in groups) ...[
            SliverToBoxAdapter(child: SectionHeader(title: title)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
              sliver: SliverToBoxAdapter(
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, (icon, label, route, badge))
                          in items.indexed) ...[
                        if (i > 0) const Divider(indent: 72),
                        ListTile(
                          key: Key('more-$route'),
                          minTileHeight: 64,
                          leading: badge > 0
                              ? Badge.count(count: badge, child: Icon(icon))
                              : Icon(icon),
                          title: Text(label),
                          subtitle: badge > 0
                              ? Text(l10n.dashboardLowStockCount(badge))
                              : null,
                          trailing: const Icon(Symbols.chevron_right_rounded),
                          onTap: () async {
                            await context.push(route);
                            ref.invalidate(lowStockCountProvider);
                          },
                        ),
                      ],
                    ],
                  ),
                ).staggerIn(context, order++),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: Gaps.xl)),
        ],
      ),
    );
  }
}
