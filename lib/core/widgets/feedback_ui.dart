import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';

/// Kind of snackbar message (sets the icon and color).
enum SnackType { info, success, warning, error }

/// Floating rounded snackbar with a semantic icon and optional action
/// (e.g. Undo).
void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackType type = SnackType.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final tokens = context.tokens;
  final scheme = Theme.of(context).colorScheme;
  final (icon, color) = switch (type) {
    SnackType.info => (Symbols.info_rounded, scheme.inversePrimary),
    SnackType.success => (
      Symbols.check_circle_rounded,
      tokens.successContainer,
    ),
    SnackType.warning => (Symbols.warning_rounded, tokens.warningContainer),
    SnackType.error => (Symbols.error_rounded, tokens.dangerContainer),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: Gaps.sm),
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
}

/// Opens a rounded, draggable bottom sheet that resizes with the keyboard.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool expand = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheetContext) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
    ),
    child: expand
        ? builder(sheetContext)
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.lg),
            child: builder(sheetContext),
          ),
  ),
);

/// Asks the user to confirm an action. Resolves to `true` only on confirm.
/// Prefer an Undo snackbar for reversible actions.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
