import 'package:flutter/material.dart';

import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/animated_counter.dart';
import 'package:tindascan/core/widgets/app_card.dart';

/// Compact metric: label, animated number and an optional icon/footer.
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    this.format,
    this.icon,
    this.footer,
    this.onTap,
    this.emphasis = false,
    super.key,
  });

  final String label;
  final int value;
  final String Function(int)? format;
  final IconData? icon;
  final Widget? footer;
  final VoidCallback? onTap;

  /// Hero styling (larger number, accent background).
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = emphasis ? scheme.onPrimaryContainer : scheme.onSurface;
    return AppCard(
      onTap: onTap,
      color: emphasis ? scheme.primaryContainer : null,
      borderColor: emphasis ? scheme.primaryContainer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: Gaps.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(color: fg),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedCounter(
              value: value,
              format: format,
              style:
                  (emphasis
                          ? theme.textTheme.displaySmall
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(color: fg),
            ),
          ),
          if (footer != null) ...[const SizedBox(height: Gaps.sm), footer!],
        ],
      ),
    );
  }
}
