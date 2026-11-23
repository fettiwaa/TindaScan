import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/connectivity/connectivity_providers.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';

/// Wraps the app and shows a strip at the bottom while offline. Firestore
/// keeps working from its local cache and syncs when the connection returns.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(
      isOnlineProvider.select((value) => value.value == false),
    );
    if (!offline) return child;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(child: child),
        Material(
          color: scheme.inverseSurface,
          child: SafeArea(
            top: false,
            child: Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gaps.md,
                  vertical: Gaps.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, color: scheme.onInverseSurface),
                    const SizedBox(width: Gaps.sm),
                    Expanded(
                      child: Text(
                        context.l10n.offlineBanner,
                        style: TextStyle(color: scheme.onInverseSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
