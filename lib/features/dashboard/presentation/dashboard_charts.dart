import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';
import 'package:tindascan/core/utils/formatters.dart';
import 'package:tindascan/core/utils/money.dart';
import 'package:tindascan/shared/models/daily_stats.dart';

const double _chartHeight = 200;
const double _sparklineHeight = 48;
const double _leftAxisReserved = 44;

/// Compact peso label for chart axes, e.g. ₱1.2k.
String compactPesos(double pesos) {
  if (pesos >= 1000) {
    final k = pesos / 1000;
    return '₱${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
  }
  return '₱${pesos.toStringAsFixed(0)}';
}

/// Daily sales line chart. On first build the line rises from zero (the
/// "draw-in" entrance) and it animates smoothly when the range changes.
/// [sparkline] hides axes, grid and touch for the hero card.
class SalesLineChart extends StatefulWidget {
  const SalesLineChart({
    required this.days,
    required this.semanticLabel,
    this.sparkline = false,
    this.color,
    super.key,
  });

  final List<DailyStats> days;
  final String semanticLabel;
  final bool sparkline;
  final Color? color;

  @override
  State<SalesLineChart> createState() => _SalesLineChartState();
}

class _SalesLineChartState extends State<SalesLineChart> {
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.color ?? scheme.primary;
    final days = widget.days;
    final motion = context.motion;
    final show = _entered || !motion.enabled;
    final values = [
      for (final d in days)
        show ? d.salesCentavos / Money.centavosPerPeso : 0.0,
    ];
    final maxY = days.fold<double>(
      0,
      (m, d) => math.max(m, d.salesCentavos / Money.centavosPerPeso),
    );
    final labelEvery = days.length <= 7 ? 1 : 5;
    final labelStyle = AppTypography.tabular(
      Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
    );

    return Semantics(
      label: widget.semanticLabel,
      child: SizedBox(
        height: widget.sparkline ? _sparklineHeight : _chartHeight,
        child: LineChart(
          duration: motion.slow,
          curve: AppMotion.enter,
          LineChartData(
            minY: 0,
            maxY: maxY == 0 ? 1 : maxY * 1.15,
            gridData: FlGridData(
              show: !widget.sparkline,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: context.tokens.cardOutline, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: widget.sparkline
                ? const LineTouchData(enabled: false)
                : LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => scheme.inverseSurface,
                      getTooltipItems: (spots) => [
                        for (final spot in spots)
                          LineTooltipItem(
                            '${AppFormat.shortDay(days[spot.x.toInt()].dayKey)}\n'
                            '${Money.format(days[spot.x.toInt()].salesCentavos)}',
                            TextStyle(color: scheme.onInverseSurface),
                          ),
                      ],
                    ),
                  ),
            titlesData: widget.sparkline
                ? const FlTitlesData(show: false)
                : FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: _leftAxisReserved,
                        getTitlesWidget: (value, meta) =>
                            Text(compactPesos(value), style: labelStyle),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 ||
                              i >= days.length ||
                              i % labelEvery != 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: Gaps.xs),
                            child: Text(
                              AppFormat.shortDay(days[i].dayKey),
                              style: labelStyle,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < values.length; i++)
                    FlSpot(i.toDouble(), values[i]),
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                color: color,
                barWidth: widget.sparkline ? 2.5 : 3,
                dotData: FlDotData(show: !widget.sparkline && days.length <= 7),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.22),
                      color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of a [ProportionalBars] list.
@immutable
class BarItem {
  const BarItem({
    required this.label,
    required this.value,
    required this.valueLabel,
    this.caption,
    this.onTap,
  });

  final String label;
  final int value;
  final String valueLabel;
  final String? caption;
  final VoidCallback? onTap;
}

/// Ranked list with bars proportional to each value; bars grow in from
/// zero on first show.
class ProportionalBars extends StatelessWidget {
  const ProportionalBars({required this.items, this.color, super.key});

  final List<BarItem> items;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final max = items.fold<int>(0, (m, i) => math.max(m, i.value));
    final barColor = color ?? scheme.primary;
    return Column(
      children: [
        for (final (index, item) in items.indexed)
          InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(AppRadii.small),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Gaps.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${index + 1}',
                          style: AppTypography.tabular(
                            theme.textTheme.labelLarge,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(width: Gaps.sm),
                      Text(
                        item.valueLabel,
                        style: AppTypography.tabular(
                          theme.textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gaps.xs),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: max == 0 ? 0 : math.max(item.value, 0) / max,
                      ),
                      duration: context.motion.slow,
                      curve: AppMotion.enter,
                      builder: (context, fraction, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 8,
                          color: barColor,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ),
                  if (item.caption != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: Gaps.xs),
                      child: Text(
                        item.caption!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
