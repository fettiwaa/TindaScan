import 'package:flutter/material.dart';

import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/motion.dart';

/// White rounded card with a thin outline (no heavy shadow). Tappable
/// cards get a press scale-down plus the Material ripple.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Gaps.md),
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.medium);
    final card = Card(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: borderColor ?? context.tokens.cardOutline),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
    );
    return onTap == null ? card : Pressable(child: card);
  }
}

/// Title row above a group of content, with an optional count badge and
/// trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.count,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      Gaps.md,
      Gaps.lg,
      Gaps.md,
      Gaps.sm,
    ),
    super.key,
  });

  final String title;
  final int? count;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Flexible(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: Gaps.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Gaps.sm,
                vertical: Gaps.xxs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                '$count',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
