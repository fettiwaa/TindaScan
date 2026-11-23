import 'package:flutter/material.dart';

import 'package:tindascan/core/theme/app_tokens.dart';

/// Inline message box announced to screen readers (live region).
class MessageBanner extends StatelessWidget {
  const MessageBanner({required this.text, this.isError = true, super.key});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.md),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(Gaps.md),
          decoration: BoxDecoration(
            color: isError ? scheme.errorContainer : scheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isError
                  ? scheme.onErrorContainer
                  : scheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
