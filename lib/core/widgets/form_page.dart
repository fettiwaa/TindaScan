import 'package:flutter/material.dart';

import 'package:tindascan/core/theme/app_tokens.dart';

/// Scrollable, width-constrained body for forms. Scrolls at large text
/// scales so nothing overflows at 1.5x.
class FormPage extends StatelessWidget {
  const FormPage({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gaps.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

/// Vertical gap between form fields.
class FieldGap extends StatelessWidget {
  const FieldGap({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: Gaps.md);
}
