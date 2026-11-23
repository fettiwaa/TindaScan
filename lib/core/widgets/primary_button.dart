import 'package:flutter/material.dart';

import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/motion.dart';

/// Full-width primary action. Shows an inline progress indicator and
/// disables itself while [isLoading] — this is what prevents double
/// submissions (e.g. double-charging a sale). Use at most one per screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onPressed != null;
    final scheme = Theme.of(context).colorScheme;
    return Pressable(
      enabled: enabled,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          child: AnimatedSwitcher(
            duration: context.motion.fast,
            child: isLoading
                ? Row(
                    key: const ValueKey('loading'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: Gaps.sm),
                      Flexible(
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('idle'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon),
                        const SizedBox(width: Gaps.sm),
                      ],
                      Flexible(
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Full-width outlined secondary action.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Pressable(
    enabled: onPressed != null,
    child: SizedBox(
      width: double.infinity,
      child: icon == null
          ? OutlinedButton(onPressed: onPressed, child: Text(label))
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon),
              label: Text(label),
            ),
    ),
  );
}
