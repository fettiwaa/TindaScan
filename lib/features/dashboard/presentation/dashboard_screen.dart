import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';
import 'package:tindascan/core/utils/formatters.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/core/utils/money.dart';
import 'package:tindascan/core/widgets/animated_counter.dart';
import 'package:tindascan/core/widgets/app_card.dart';
import 'package:tindascan/core/widgets/motion.dart';
import 'package:tindascan/core/widgets/stat_card.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/features/alerts/application/alert_providers.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/dashboard/application/dashboard_providers.dart';
import 'package:tindascan/features/dashboard/domain/stats_aggregation.dart';
import 'package:tindascan/features/dashboard/presentation/dashboard_charts.dart';
import 'package:tindascan/shared/models/daily_stats.dart';
import 'package:tindascan/shared/models/product.dart';

/// Owner dashboard: greeting, today's hero numbers, trend, best-sellers,
/// lowest stock.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final name = ref.watch(currentUserProvider.select((u) => u?.name ?? ''));
    final now = ref.watch(clockProvider)();

    Future<void> refresh() async {
      ref
        ..invalidate(dashboardStatsProvider)
        ..invalidate(lowestStockProvider)
        ..invalidate(lowStockCountProvider);
      await ref.read(dashboardStatsProvider.future);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Greeting(name: name, now: now),
              ),
              ...switch (stats) {
                AsyncData(:final value) => [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Gaps.md,
                      0,
                      Gaps.md,
                      Gaps.xl,
                    ),
                    sliver: SliverList.list(
                      children: [
                        _HeroCard(days: value).enterSection(context),
                        const SizedBox(height: Gaps.md),
                        _StatChips(days: value).enterSection(context, order: 1),
                        const SizedBox(height: Gaps.md),
                        _TrendCard(days: value).enterSection(context, order: 2),
                        const SizedBox(height: Gaps.md),
                        _TopSellersCard(
                          days: value,
                        ).enterSection(context, order: 3),
                        const SizedBox(height: Gaps.md),
                        const _LowestStockCard().enterSection(
                          context,
                          order: 4,
                        ),
                      ],
                    ),
                  ),
                ],
                AsyncError(:final error) => [
                  SliverFillRemaining(
                    child: ErrorState(
                      error: error,
                      onRetry: () => ref.invalidate(dashboardStatsProvider),
                    ),
                  ),
                ],
                _ => [const SliverFillRemaining(child: _DashboardSkeleton())],
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.now});

  final String name;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gaps.md, Gaps.lg, Gaps.md, Gaps.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppFormat.date(context, now),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Gaps.xs),
          Text(
            context.l10n.homeGreeting(name),
            style: theme.textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.days});

  final List<DailyStats> days;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = days.isEmpty ? null : days.last;
    final yesterday = days.length < 2 ? null : days[days.length - 2];
    final sales = today?.salesCentavos ?? 0;
    final before = yesterday?.salesCentavos ?? 0;
    final fg = scheme.onPrimaryContainer;

    final Widget delta;
    if (before <= 0) {
      delta = Text(
        l10n.dashboardNoYesterday,
        style: theme.textTheme.labelLarge?.copyWith(color: fg),
      );
    } else {
      final percent = ((sales - before) / before * 100).round();
      final up = percent >= 0;
      delta = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Symbols.trending_up_rounded : Symbols.trending_down_rounded,
            size: 18,
            color: fg,
          ),
          const SizedBox(width: Gaps.xs),
          Text(
            l10n.dashboardVsYesterday('${up ? '+' : ''}$percent%'),
            style: AppTypography.tabular(
              theme.textTheme.labelLarge?.copyWith(color: fg),
            ),
          ),
        ],
      );
    }

    final week = days.length > 7 ? days.sublist(days.length - 7) : days;
    return AppCard(
      color: scheme.primaryContainer,
      borderColor: scheme.primaryContainer,
      padding: const EdgeInsets.all(Gaps.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardTodaySales,
            style: theme.textTheme.titleMedium?.copyWith(color: fg),
          ),
          const SizedBox(height: Gaps.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedCounter.money(
              key: const Key('today-sales'),
              centavos: sales,
              style: theme.textTheme.displayMedium?.copyWith(color: fg),
            ),
          ),
          const SizedBox(height: Gaps.sm),
          delta,
          const SizedBox(height: Gaps.md),
          SalesLineChart(
            days: week,
            sparkline: true,
            color: scheme.primary,
            semanticLabel: l10n.dashboardSalesTrend,
          ),
        ],
      ),
    );
  }
}

class _StatChips extends ConsumerWidget {
  const _StatChips({required this.days});

  final List<DailyStats> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final today = days.isEmpty ? null : days.last;
    final lowStock = ref.watch(lowStockCountProvider).value ?? 0;
    final cards = [
      StatCard(
        label: l10n.dashboardTransactions,
        icon: Symbols.receipt_long_rounded,
        value: today?.transactionCount ?? 0,
      ),
      StatCard(
        label: l10n.dashboardProfit,
        icon: Symbols.savings_rounded,
        value: today?.profitCentavos ?? 0,
        format: Money.format,
      ),
      StatCard(
        key: const Key('stat-low-stock'),
        label: l10n.productsLowStockFilter,
        icon: Symbols.warning_rounded,
        value: lowStock,
        onTap: () => context.push(AppRoutes.alerts),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Three across when there is room; otherwise scroll sideways.
        if (constraints.maxWidth >= Breakpoints.medium) {
          return Row(
            children: [
              for (final (i, card) in cards.indexed) ...[
                if (i > 0) const SizedBox(width: Gaps.md),
                Expanded(child: card),
              ],
            ],
          );
        }
        return SizedBox(
          height:
              128 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: Gaps.sm),
            itemBuilder: (_, i) => SizedBox(width: 168, child: cards[i]),
          ),
        );
      },
    );
  }
}

class _TrendCard extends ConsumerWidget {
  const _TrendCard({required this.days});

  final List<DailyStats> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final range = ref.watch(dashboardRangeProvider);
    final total = StatsAggregation.summarize(days);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wrap (not Row) so the toggle drops below the title at large
          // text sizes instead of overflowing.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Gaps.sm,
            runSpacing: Gaps.sm,
            children: [
              Text(
                l10n.dashboardSalesTrend,
                style: theme.textTheme.titleMedium,
              ),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: DashboardRange.week,
                    label: Text(l10n.reports7d),
                  ),
                  ButtonSegment(
                    value: DashboardRange.month,
                    label: Text(l10n.reports30d),
                  ),
                ],
                selected: {range},
                onSelectionChanged: (s) =>
                    ref.read(dashboardRangeProvider.notifier).set(s.first),
              ),
            ],
          ),
          const SizedBox(height: Gaps.sm),
          Text(
            '${l10n.reportsSalesCol} ${Money.format(total.salesCentavos)} · '
            '${l10n.reportsProfitCol} ${Money.format(total.profitCentavos)}',
            style: AppTypography.tabular(theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: Gaps.md),
          SalesLineChart(
            days: days,
            semanticLabel:
                '${l10n.dashboardSalesTrend}: ${Money.format(total.salesCentavos)}',
          ),
        ],
      ),
    );
  }
}

class _TopSellersCard extends StatelessWidget {
  const _TopSellersCard({required this.days});

  final List<DailyStats> days;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final top = StatsAggregation.topSellers(
      days,
      limit: AppConstants.topSellerCount,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dashboardTopSellers,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Gaps.sm),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Gaps.md),
              child: Text(
                l10n.dashboardNoSales,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ProportionalBars(
              items: [
                for (final p in top)
                  BarItem(
                    label: p.name,
                    value: p.qty,
                    valueLabel: l10n.dashboardSold(p.qty),
                    caption: Money.format(p.salesCentavos),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LowestStockCard extends ConsumerWidget {
  const _LowestStockCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final products = ref.watch(lowestStockProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.dashboardLowestStock,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Gaps.sm),
          switch (products) {
            AsyncData(value: final List<Product> list) when list.isEmpty =>
              Text(l10n.productsEmpty),
            AsyncData(value: final List<Product> list) => ProportionalBars(
              color: context.tokens.warning,
              items: [
                for (final p in list)
                  BarItem(
                    label: p.name,
                    value: p.stockQty,
                    valueLabel: l10n.productStockCount(p.stockQty),
                    onTap: () => context.push(AppRoutes.productDetail(p.id)),
                  ),
              ],
            ),
            AsyncError(:final error) => ErrorState(
              error: error,
              onRetry: () => ref.invalidate(lowestStockProvider),
            ),
            _ => const SizedBox(
              height: 160,
              child: SkeletonList(itemCount: 3, leading: false),
            ),
          },
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: Gaps.md),
    child: SkeletonList(itemCount: 6, leading: false),
  );
}
