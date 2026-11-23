import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';
import 'package:tindascan/core/utils/formatters.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/core/utils/money.dart';
import 'package:tindascan/core/widgets/feedback_ui.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/motion.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/core/widgets/stat_card.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/features/dashboard/domain/stats_aggregation.dart';
import 'package:tindascan/features/dashboard/presentation/dashboard_charts.dart';
import 'package:tindascan/features/reports/application/report_providers.dart';
import 'package:tindascan/features/reports/domain/excel_export.dart';
import 'package:tindascan/features/reports/domain/report_filter.dart';
import 'package:tindascan/features/reports/presentation/report_sheets.dart';
import 'package:tindascan/features/stock/presentation/movement_labels.dart';
import 'package:tindascan/shared/models/daily_stats.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/models/stock_movement.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// Quick date ranges.
enum _RangePreset { today, week, month, custom }

/// Owner reports: date range, report type, summary cards, list, and a
/// prominent Excel export. Phones stack everything; tablets put the
/// controls in a left pane.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static ReportSheets sheetsFor(BuildContext context) => ReportSheets(
    context.l10n,
    formatDate: (d) => AppFormat.dateTime(context, d),
    formatDayKey: (k) => AppFormat.dayKey(context, k),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(reportFilterProvider);
    final content = switch (filter.type) {
      ReportType.sales => const _SalesReport(),
      ReportType.bestSellers => const _BestSellersReport(),
      ReportType.inventory => const _InventoryReport(),
      ReportType.movements => const _MovementsReport(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= Breakpoints.medium;
        if (wide) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.reportsTitle)),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: AppSizes.listPaneWidth,
                  child: ListView(
                    padding: const EdgeInsets.all(Gaps.md),
                    children: const [
                      _Controls(vertical: true),
                      SizedBox(height: Gaps.lg),
                      _ExportButton(),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.reportsTitle)),
          body: Column(
            children: [
              const _Controls(vertical: false),
              Expanded(child: content),
            ],
          ),
          bottomNavigationBar: const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(Gaps.md, Gaps.sm, Gaps.md, Gaps.md),
              child: _ExportButton(),
            ),
          ),
        );
      },
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.vertical});

  final bool vertical;

  _RangePreset _presetOf(ReportFilter filter, DateTime now) {
    final today = ManilaTime.startOfDay(now);
    if (filter.to != today) return _RangePreset.custom;
    return switch (filter.dayCount) {
      1 => _RangePreset.today,
      7 => _RangePreset.week,
      30 => _RangePreset.month,
      _ => _RangePreset.custom,
    };
  }

  void _applyPreset(WidgetRef ref, int days) {
    final now = ref.read(clockProvider)();
    final filter = ref.read(reportFilterProvider);
    ref
        .read(reportFilterProvider.notifier)
        .update(
          filter.copyWith(
            from: ManilaTime.startOfDay(now.subtract(Duration(days: days - 1))),
            to: ManilaTime.startOfDay(now),
          ),
        );
  }

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final filter = ref.read(reportFilterProvider);
    final now = ref.read(clockProvider)();
    final todayWall = ManilaTime.wallClock(now);
    DateTime toLocal(DateTime instant) {
      final w = ManilaTime.wallClock(instant);
      return DateTime(w.year, w.month, w.day);
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(todayWall.year - 5),
      lastDate: DateTime(todayWall.year, todayWall.month, todayWall.day),
      initialDateRange: DateTimeRange(
        start: toLocal(filter.from),
        end: toLocal(filter.to),
      ),
    );
    if (picked == null || !context.mounted) return;
    DateTime manilaStart(DateTime d) =>
        DateTime.utc(d.year, d.month, d.day).subtract(ManilaTime.offset);
    final next = filter.copyWith(
      from: manilaStart(picked.start),
      to: manilaStart(picked.end),
    );
    if (next.dayCount > AppConstants.maxReportDays) {
      showAppSnackBar(
        context,
        l10n.reportsRangeTooLong(AppConstants.maxReportDays),
        type: SnackType.warning,
      );
      return;
    }
    ref.read(reportFilterProvider.notifier).update(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(reportFilterProvider);
    final notifier = ref.read(reportFilterProvider.notifier);
    final preset = _presetOf(filter, ref.watch(clockProvider)());
    final keys = filter.dayKeys;
    final rangeText = keys.length == 1
        ? AppFormat.dayKey(context, keys.first)
        : '${AppFormat.dayKey(context, keys.first)} – '
              '${AppFormat.dayKey(context, keys.last)}';
    final rangeEnabled = filter.type != ReportType.inventory;

    final rangeChips = [
      ChoiceChip(
        label: Text(l10n.reportsToday),
        selected: preset == _RangePreset.today,
        onSelected: rangeEnabled ? (_) => _applyPreset(ref, 1) : null,
      ),
      ChoiceChip(
        label: Text(l10n.reports7d),
        selected: preset == _RangePreset.week,
        onSelected: rangeEnabled ? (_) => _applyPreset(ref, 7) : null,
      ),
      ChoiceChip(
        label: Text(l10n.reports30d),
        selected: preset == _RangePreset.month,
        onSelected: rangeEnabled ? (_) => _applyPreset(ref, 30) : null,
      ),
      ChoiceChip(
        avatar: const Icon(Symbols.date_range_rounded),
        label: Text(l10n.reportsCustom),
        selected: preset == _RangePreset.custom,
        onSelected: rangeEnabled ? (_) => _pickRange(context, ref) : null,
      ),
    ];
    final types = {
      ReportType.sales: l10n.reportsSales,
      ReportType.bestSellers: l10n.reportsBestSellers,
      ReportType.inventory: l10n.reportsInventory,
      ReportType.movements: l10n.reportsMovements,
    };
    final typeChips = [
      for (final entry in types.entries)
        ChoiceChip(
          label: Text(entry.value),
          selected: filter.type == entry.key,
          onSelected: (_) => notifier.update(filter.copyWith(type: entry.key)),
        ),
    ];

    Widget chipRow(List<Widget> chips) => vertical
        ? Wrap(spacing: Gaps.sm, runSpacing: Gaps.sm, children: chips)
        : SizedBox(
            height: AppSizes.minTapTarget + Gaps.sm,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
              itemCount: chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: Gaps.sm),
              itemBuilder: (_, i) => Center(child: chips[i]),
            ),
          );

    final pad = vertical
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(horizontal: Gaps.md);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        chipRow(typeChips),
        if (rangeEnabled) ...[
          chipRow(rangeChips),
          Padding(
            padding: pad,
            child: Text(
              rangeText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        if (filter.type == ReportType.sales)
          Padding(
            padding: pad.add(const EdgeInsets.only(top: Gaps.sm)),
            child: SegmentedButton<ReportGrouping>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ReportGrouping.daily,
                  label: Text(l10n.reportsGroupDaily),
                ),
                ButtonSegment(
                  value: ReportGrouping.weekly,
                  label: Text(l10n.reportsGroupWeekly),
                ),
                ButtonSegment(
                  value: ReportGrouping.monthly,
                  label: Text(l10n.reportsGroupMonthly),
                ),
              ],
              selected: {filter.grouping},
              onSelectionChanged: (s) =>
                  notifier.update(filter.copyWith(grouping: s.first)),
            ),
          ),
        const SizedBox(height: Gaps.sm),
      ],
    );
  }
}

class _ExportButton extends ConsumerWidget {
  const _ExportButton();

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final sheets = ReportsScreen.sheetsFor(context);
    final filter = ref.read(reportFilterProvider);
    try {
      final List<ExcelSheetSpec> specs;
      switch (filter.type) {
        case ReportType.sales:
          final days = await ref.read(reportStatsProvider.future);
          final sales = await ref
              .read(salesRepositoryProvider)
              .salesBetween(filter.from, filter.toExclusive);
          specs = [
            sheets.sales(StatsAggregation.group(days, filter.grouping)),
            sheets.transactions(sales),
          ];
        case ReportType.bestSellers:
          final days = await ref.read(reportStatsProvider.future);
          specs = [sheets.bestSellers(StatsAggregation.topSellers(days))];
        case ReportType.inventory:
          specs = [
            sheets.inventory(await ref.read(reportInventoryProvider.future)),
          ];
        case ReportType.movements:
          specs = [
            sheets.movements(await ref.read(reportMovementsProvider.future)),
          ];
      }
      final keys = filter.dayKeys;
      final ok = await ref
          .read(reportExporterProvider.notifier)
          .export(
            ExcelReportSpec(specs),
            fileName:
                'TindaScan_${filter.type.name}_${keys.first}-${keys.last}.xlsx',
          );
      if (!context.mounted) return;
      if (ok) {
        showAppSnackBar(context, l10n.reportsExported, type: SnackType.success);
      } else {
        final error = ref.read(reportExporterProvider).error;
        showAppSnackBar(
          context,
          (error ?? '').toUserMessage(l10n),
          type: SnackType.error,
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          error.toUserMessage(l10n),
          type: SnackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => PrimaryButton(
    key: const Key('export-excel'),
    label: context.l10n.reportsExport,
    icon: Symbols.download_rounded,
    isLoading: ref.watch(reportExporterProvider).isLoading,
    onPressed: () => _export(context, ref),
  );
}

/// Summary cards that wrap at large text sizes.
class _Summary extends StatelessWidget {
  const _Summary({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Gaps.md, Gaps.sm, Gaps.md, Gaps.md),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth >= 720 ? cards.length : 2;
        final width = (constraints.maxWidth - Gaps.sm * (perRow - 1)) / perRow;
        return Wrap(
          spacing: Gaps.sm,
          runSpacing: Gaps.sm,
          children: [
            for (final (i, card) in cards.indexed)
              SizedBox(width: width, child: card.staggerIn(context, i)),
          ],
        );
      },
    ),
  );
}

class _SalesReport extends ConsumerWidget {
  const _SalesReport();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sheets = ReportsScreen.sheetsFor(context);
    final grouping = ref.watch(reportFilterProvider.select((f) => f.grouping));
    final stats = ref.watch(reportStatsProvider);
    return AsyncValueView<List<DailyStats>>(
      value: stats,
      onRetry: () => ref.invalidate(reportStatsProvider),
      isEmpty: (days) => days.every((d) => d.transactionCount == 0),
      emptyMessage: l10n.reportsEmpty,
      emptyIcon: Symbols.bar_chart_rounded,
      data: (days) {
        final rows = StatsAggregation.group(days, grouping).reversed.toList();
        final total = StatsAggregation.summarize(days);
        return ListView.builder(
          itemCount: rows.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _Summary(
                cards: [
                  StatCard(
                    label: l10n.reportsSalesCol,
                    value: total.salesCentavos,
                    format: Money.format,
                  ),
                  StatCard(
                    label: l10n.reportsProfitCol,
                    value: total.profitCentavos,
                    format: Money.format,
                  ),
                  StatCard(
                    label: l10n.reportsTransactionsCol,
                    value: total.transactionCount,
                  ),
                  StatCard(label: l10n.reportsItemsCol, value: total.itemsSold),
                ],
              );
            }
            final row = rows[index - 1];
            return ListTile(
              title: Text(sheets.periodLabel(row)),
              subtitle: Text(
                '${l10n.reportsTransactionsCol}: ${row.summary.transactionCount}',
              ),
              trailing: _MoneyPair(
                sales: row.summary.salesCentavos,
                profit: row.summary.profitCentavos,
              ),
            ).staggerIn(context, index);
          },
        );
      },
    );
  }
}

class _MoneyPair extends StatelessWidget {
  const _MoneyPair({required this.sales, required this.profit});

  final int sales;
  final int profit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          Money.format(sales),
          style: AppTypography.tabular(theme.textTheme.titleMedium),
        ),
        Text(
          '${context.l10n.reportsProfitCol} ${Money.format(profit)}',
          style: AppTypography.tabular(theme.textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _BestSellersReport extends ConsumerWidget {
  const _BestSellersReport();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(reportStatsProvider);
    return AsyncValueView<List<DailyStats>>(
      value: stats,
      onRetry: () => ref.invalidate(reportStatsProvider),
      isEmpty: (days) => StatsAggregation.topSellers(days).isEmpty,
      emptyMessage: l10n.reportsEmpty,
      emptyIcon: Symbols.leaderboard_rounded,
      data: (days) {
        final top = StatsAggregation.topSellers(days);
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
          children: [
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
            const SizedBox(height: Gaps.lg),
          ],
        );
      },
    );
  }
}

class _InventoryReport extends ConsumerWidget {
  const _InventoryReport();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final products = ref.watch(reportInventoryProvider);
    return AsyncValueView<List<Product>>(
      value: products,
      onRetry: () => ref.invalidate(reportInventoryProvider),
      isEmpty: (list) => list.isEmpty,
      emptyMessage: l10n.reportsEmpty,
      emptyIcon: Symbols.inventory_2_rounded,
      data: (list) {
        final value = list.fold<int>(
          0,
          (sum, p) => sum + ReportSheets.stockValue(p),
        );
        final units = list.fold<int>(
          0,
          (sum, p) => sum + (p.stockQty < 0 ? 0 : p.stockQty),
        );
        return ListView.builder(
          itemCount: list.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Column(
                children: [
                  _Summary(
                    cards: [
                      StatCard(
                        label: l10n.reportsValueCol,
                        value: value,
                        format: Money.format,
                      ),
                      StatCard(label: l10n.reportsStockCol, value: units),
                    ],
                  ),
                  if (list.length >= AppConstants.maxReportProducts)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
                      child: MessageBanner(
                        text: l10n.reportsCapped(
                          AppConstants.maxReportProducts,
                        ),
                        isError: false,
                      ),
                    ),
                ],
              );
            }
            final p = list[i - 1];
            return ListTile(
              title: Text(p.name),
              subtitle: Text(l10n.productStockCount(p.stockQty)),
              trailing: Text(
                Money.format(ReportSheets.stockValue(p)),
                style: AppTypography.tabular(
                  Theme.of(context).textTheme.titleSmall,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MovementsReport extends ConsumerWidget {
  const _MovementsReport();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final movements = ref.watch(reportMovementsProvider);
    return AsyncValueView<List<StockMovement>>(
      value: movements,
      onRetry: () => ref.invalidate(reportMovementsProvider),
      isEmpty: (list) => list.isEmpty,
      emptyMessage: l10n.reportsEmpty,
      emptyIcon: Symbols.swap_vert_rounded,
      data: (list) => ListView.builder(
        itemCount: list.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return list.length >= AppConstants.maxReportMovements
                ? Padding(
                    padding: const EdgeInsets.all(Gaps.md),
                    child: MessageBanner(
                      text: l10n.reportsCapped(AppConstants.maxReportMovements),
                      isError: false,
                    ),
                  )
                : const SizedBox(height: Gaps.sm);
          }
          final m = list[i - 1];
          final created = m.createdAt;
          final positive = m.qtyChange > 0;
          return ListTile(
            leading: Icon(m.type.icon),
            title: Text(m.productName),
            subtitle: Text(
              [
                m.type.label(l10n),
                if (created != null) AppFormat.dateTime(context, created),
                if (m.userName.isNotEmpty) l10n.movementBy(m.userName),
              ].join(' · '),
            ),
            trailing: Text(
              positive ? '+${m.qtyChange}' : '${m.qtyChange}',
              style: AppTypography.tabular(
                Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: positive
                      ? context.tokens.success
                      : context.tokens.danger,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
