import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/motion.dart';

/// Centered progress indicator (prefer [SkeletonList] for lists).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: context.l10n.loading,
      child: const CircularProgressIndicator(),
    ),
  );
}

/// Empty state: one icon, one sentence, at most one action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon = Symbols.inbox_rounded,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gaps.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(Gaps.lg),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: Gaps.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Gaps.md),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ).enterSection(context),
    );
  }
}

/// Friendly error message with a retry button.
class ErrorState extends StatelessWidget {
  const ErrorState({required this.error, this.onRetry, super.key});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Symbols.cloud_off_rounded,
    message: error.toUserMessage(context.l10n),
    actionLabel: onRetry == null ? null : context.l10n.retry,
    onAction: onRetry,
  );
}

/// Older names kept for existing call sites.
typedef EmptyView = EmptyState;
typedef ErrorView = ErrorState;

/// Shimmering placeholder rows shaped like the real list.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.itemCount = 8, this.leading = true, super.key});

  final int itemCount;
  final bool leading;

  @override
  Widget build(BuildContext context) => Skeletonizer(
    child: ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => ListTile(
        leading: leading ? const CircleAvatar() : null,
        title: const Text('Placeholder product name'),
        subtitle: const Text('₱00.00 · 00 in stock'),
      ),
    ),
  );
}

/// Renders loading (skeleton) / error (with retry) / empty / data for an
/// [AsyncValue].
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.data,
    this.onRetry,
    this.isEmpty,
    this.emptyMessage,
    this.emptyIcon = Symbols.inbox_rounded,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.loading,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  /// Returns true when [data] should be replaced by the empty state.
  final bool Function(T data)? isEmpty;
  final String? emptyMessage;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  /// Loading placeholder; defaults to a skeleton list.
  final Widget? loading;

  @override
  Widget build(BuildContext context) => switch (value) {
    AsyncData(:final value) when isEmpty?.call(value) ?? false => EmptyState(
      message: emptyMessage ?? context.l10n.nothingHereYet,
      icon: emptyIcon,
      actionLabel: emptyActionLabel,
      onAction: onEmptyAction,
    ),
    AsyncData(:final value) => data(value),
    AsyncError(:final error) => ErrorState(error: error, onRetry: onRetry),
    _ => loading ?? const SkeletonList(),
  };
}
