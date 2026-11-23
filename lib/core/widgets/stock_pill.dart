import 'package:flutter/material.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';

/// Stock level status.
enum StockLevel {
  ok,
  low,
  out;

  static StockLevel of({required int stock, required int threshold}) =>
      stock <= 0
      ? StockLevel.out
      : stock <= threshold
      ? StockLevel.low
      : StockLevel.ok;
}

/// Rounded pill showing stock: green (ok), amber (low), red (out).
class StockPill extends StatelessWidget {
  const StockPill({required this.stock, required this.threshold, super.key});

  final int stock;
  final int threshold;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final level = StockLevel.of(stock: stock, threshold: threshold);
    final (bg, fg, label) = switch (level) {
      StockLevel.ok => (
        tokens.successContainer,
        tokens.onSuccessContainer,
        l10n.productStockCount(stock),
      ),
      StockLevel.low => (
        tokens.warningContainer,
        tokens.onWarningContainer,
        l10n.stockPillLow(stock),
      ),
      StockLevel.out => (
        tokens.dangerContainer,
        tokens.onDangerContainer,
        l10n.sellOutOfStock,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gaps.sm + Gaps.xs,
        vertical: Gaps.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: AppTypography.tabular(
          Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
        ),
      ),
    );
  }
}
