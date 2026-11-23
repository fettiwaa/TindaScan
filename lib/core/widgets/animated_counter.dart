import 'package:flutter/material.dart';

import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';
import 'package:tindascan/core/utils/money.dart';

/// Number that tweens from its previous value to [value] (count-up).
/// Uses tabular figures so digits do not jitter, and jumps straight to the
/// final value when animations are disabled.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    required this.value,
    this.format,
    this.style,
    this.textAlign,
    super.key,
  });

  /// Formats money (centavos) with the app's single money formatter.
  const AnimatedCounter.money({
    required int centavos,
    TextStyle? style,
    TextAlign? textAlign,
    Key? key,
  }) : this(
         value: centavos,
         format: Money.format,
         style: style,
         textAlign: textAlign,
         key: key,
       );

  final int value;
  final String Function(int value)? format;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.tabular(
      this.style ?? Theme.of(context).textTheme.headlineMedium,
    );
    final text = format ?? (v) => '$v';
    return Semantics(
      label: text(value),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: value.toDouble()),
        duration: context.motion.slow,
        curve: AppMotion.enter,
        builder: (context, current, _) =>
            Text(text(current.round()), style: style, textAlign: textAlign),
      ),
    );
  }
}
