import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';

/// Labeled text field with the app's rounded style.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.icon,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.maxLength,
    this.autofocus = false,
    this.readOnly = false,
    this.suffix,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final IconData? icon;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;
  final bool autofocus;
  final bool readOnly;
  final Widget? suffix;
  final TextCapitalization textCapitalization;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    textInputAction: textInputAction,
    onChanged: onChanged,
    onFieldSubmitted: onSubmitted,
    maxLength: maxLength,
    autofocus: autofocus,
    readOnly: readOnly,
    textCapitalization: textCapitalization,
    style: style,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffix,
      counterText: '',
    ),
  );
}

/// Compact −/qty/+ control with 48dp targets and an animated number.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max,
    this.valueKey,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int? max;

  /// Key for the number text (tests).
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final canDecrease = value > min;
    final canIncrease = max == null || value < max!;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: context.tokens.cardOutline),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.sellDecrease,
            icon: Icon(
              value <= 1 && min == 0
                  ? Symbols.delete_rounded
                  : Symbols.remove_rounded,
            ),
            onPressed: canDecrease ? () => onChanged(value - 1) : null,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 24),
            child: AnimatedSwitcher(
              duration: context.motion.fast,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Text(
                '$value',
                key: valueKey ?? ValueKey(value),
                textAlign: TextAlign.center,
                style: AppTypography.tabular(
                  Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.sellIncrease,
            color: scheme.primary,
            icon: const Icon(Symbols.add_rounded),
            onPressed: canIncrease ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
