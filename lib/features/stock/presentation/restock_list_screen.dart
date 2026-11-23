import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';
import 'package:tindascan/core/widgets/app_card.dart';
import 'package:tindascan/core/widgets/motion.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/features/alerts/application/alert_providers.dart';
import 'package:tindascan/features/products/presentation/product_tile.dart';
import 'package:tindascan/features/stock/domain/restock.dart';
import 'package:tindascan/features/stock/presentation/stock_adjust_screen.dart';

/// Suggested shopping list for restocking low-stock products. Tapping an
/// item opens the restock sheet prefilled with the suggested quantity.
class RestockListScreen extends ConsumerWidget {
  const RestockListScreen({super.key});

  String _shareText(AppLocalizations l10n, List<RestockSuggestion> list) {
    final buffer = StringBuffer()..writeln(l10n.restockShareTitle);
    for (final s in list) {
      buffer.writeln('- ${s.product.name}: ${l10n.restockNeeded(s.qtyNeeded)}');
    }
    return buffer.toString().trimRight();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final suggestions = ref
        .watch(lowStockProductsProvider)
        .whenData(Restock.suggestions);
    final list = suggestions.value ?? const <RestockSuggestion>[];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(l10n.restockTitle),
            actions: [
              if (list.isNotEmpty)
                IconButton(
                  tooltip: l10n.share,
                  icon: const Icon(Symbols.share_rounded),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      subject: l10n.restockShareTitle,
                      text: _shareText(l10n, list),
                    ),
                  ),
                ),
            ],
          ),
          ...switch (suggestions) {
            AsyncData(:final value) when value.isEmpty => [
              SliverFillRemaining(
                child: EmptyState(
                  message: l10n.restockEmpty,
                  icon: Symbols.inventory_rounded,
                ),
              ),
            ],
            AsyncData(:final value) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Gaps.md,
                    0,
                    Gaps.md,
                    Gaps.md,
                  ),
                  child: Text(
                    l10n.restockExplain(AppConstants.restockTargetMultiplier),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
                sliver: SliverList.separated(
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Gaps.sm),
                  itemBuilder: (context, index) {
                    final s = value[index];
                    return AppCard(
                      padding: const EdgeInsets.all(Gaps.sm),
                      onTap: () async {
                        final changed = await showStockAdjustSheet(
                          context,
                          s.product,
                          suggestedQty: s.qtyNeeded,
                        );
                        if (changed) ref.invalidate(lowStockProductsProvider);
                      },
                      child: ProductTile(
                        product: s.product,
                        hero: false,
                        trailing: Text(
                          l10n.restockNeeded(s.qtyNeeded),
                          style: AppTypography.tabular(
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ).staggerIn(context, index);
                  },
                ),
              ),
            ],
            AsyncError(:final error) => [
              SliverFillRemaining(
                child: ErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(lowStockProductsProvider),
                ),
              ),
            ],
            _ => [
              SliverList.builder(
                itemCount: 6,
                itemBuilder: (_, _) => const Skeletonizer(
                  child: ListTile(
                    leading: CircleAvatar(),
                    title: Text('Placeholder product name'),
                    trailing: Text('Buy 00'),
                  ),
                ),
              ),
            ],
          },
          const SliverToBoxAdapter(child: SizedBox(height: Gaps.xl)),
        ],
      ),
    );
  }
}
