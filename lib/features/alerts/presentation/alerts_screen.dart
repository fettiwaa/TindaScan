import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/utils/formatters.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/core/widgets/app_card.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/features/alerts/application/alert_providers.dart';
import 'package:tindascan/features/products/presentation/product_tile.dart';
import 'package:tindascan/features/stock/domain/restock.dart';
import 'package:tindascan/features/stock/presentation/stock_adjust_screen.dart';
import 'package:tindascan/shared/models/product.dart';

/// Grouped alerts: out of stock (incl. negative after offline sales), low
/// stock and expiring soon, each with a one-tap Restock.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  void _refresh(WidgetRef ref) => ref
    ..invalidate(lowStockProductsProvider)
    ..invalidate(negativeStockProductsProvider)
    ..invalidate(expiringProductsProvider)
    ..invalidate(lowStockCountProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final low = ref.watch(lowStockProductsProvider);
    final negative = ref.watch(negativeStockProductsProvider);
    final expiring = ref.watch(expiringProductsProvider);
    final now = ref.watch(clockProvider)();

    final error = low.error ?? negative.error ?? expiring.error;
    final loading = low.isLoading || negative.isLoading || expiring.isLoading;
    final lowList = low.value ?? const <Product>[];
    final negativeList = negative.value ?? const <Product>[];

    final outOfStock = {
      for (final p in [
        ...negativeList,
        ...lowList.where((p) => p.stockQty <= 0),
      ])
        p.id: p,
    }.values.toList();
    final lowOnly = lowList.where((p) => p.stockQty > 0).toList();
    final expiringList = expiring.value ?? const <Product>[];

    Future<void> restock(Product product) async {
      final changed = await showStockAdjustSheet(
        context,
        product,
        suggestedQty: Restock.targetFor(product) - product.stockQty,
      );
      if (changed) _refresh(ref);
    }

    List<Widget> section({
      required String title,
      required List<Product> items,
      required IconData icon,
      required Color color,
      Widget? header,
      bool showExpiry = false,
    }) {
      if (items.isEmpty) return const [];
      return [
        SliverToBoxAdapter(
          child: SectionHeader(
            title: title,
            count: items.length,
            trailing: Icon(icon, color: color),
          ),
        ),
        if (header != null)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
            sliver: SliverToBoxAdapter(child: header),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
          sliver: SliverToBoxAdapter(
            child: AppCard(
              padding: const EdgeInsets.symmetric(vertical: Gaps.xs),
              child: Column(
                children: [
                  for (final (i, p) in items.indexed) ...[
                    if (i > 0) const Divider(indent: 72),
                    ProductTile(
                      product: p,
                      hero: false,
                      onTap: () => context.push(AppRoutes.productDetail(p.id)),
                      trailing: showExpiry && p.expiryDate != null
                          ? Text(
                              p.isExpired(now)
                                  ? l10n.productExpired
                                  : AppFormat.date(context, p.expiryDate!),
                              style: TextStyle(color: color),
                            )
                          : FilledButton.tonal(
                              onPressed: () => restock(p),
                              child: Text(l10n.alertsRestockAction),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ];
    }

    final tokens = context.tokens;
    final everythingFine =
        !loading &&
        error == null &&
        outOfStock.isEmpty &&
        lowOnly.isEmpty &&
        expiringList.isEmpty;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _refresh(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(title: Text(l10n.alertsTitle)),
            if (error != null)
              SliverFillRemaining(
                child: ErrorState(error: error, onRetry: () => _refresh(ref)),
              )
            else if (loading)
              SliverList.builder(
                itemCount: 6,
                itemBuilder: (_, _) => const Skeletonizer(
                  child: ListTile(
                    leading: CircleAvatar(),
                    title: Text('Placeholder product name'),
                    subtitle: Text('₱00.00'),
                  ),
                ),
              )
            else if (everythingFine)
              SliverFillRemaining(
                child: EmptyState(
                  message: l10n.alertsLowStockEmpty,
                  icon: Symbols.verified_rounded,
                ),
              )
            else ...[
              ...section(
                title: l10n.alertsOutOfStock,
                items: outOfStock,
                icon: Symbols.block_rounded,
                color: tokens.danger,
                header: negativeList.isEmpty
                    ? null
                    : MessageBanner(
                        text: l10n.alertsNegativeExplain,
                        isError: false,
                      ),
              ),
              ...section(
                title: l10n.alertsLowStock,
                items: lowOnly,
                icon: Symbols.warning_rounded,
                color: tokens.warning,
              ),
              ...section(
                title: l10n.alertsExpiringSoon,
                items: expiringList,
                icon: Symbols.event_busy_rounded,
                color: tokens.warning,
                showExpiry: true,
              ),
              if (expiringList.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Gaps.md,
                      Gaps.lg,
                      Gaps.md,
                      0,
                    ),
                    child: Text(
                      l10n.alertsExpiringEmpty(AppConstants.expiryWarningDays),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: Gaps.xl)),
          ],
        ),
      ),
    );
  }
}
