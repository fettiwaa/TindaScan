import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';
import 'package:tindascan/core/widgets/motion.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/sales/application/cart_notifier.dart';
import 'package:tindascan/features/scanner/presentation/barcode_scanner_view.dart';
import 'package:tindascan/features/scanner/presentation/manual_barcode_field.dart';
import 'package:tindascan/features/settings/application/app_preferences.dart';

/// Opens continuous scanning in a tall rounded sheet: every accepted scan
/// adds one unit to the cart, while a mini cart counter pulses.
Future<void> showScannerSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF101312),
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.92,
        child: _ScannerSheet(),
      ),
    );

class _ScannerSheet extends ConsumerStatefulWidget {
  const _ScannerSheet();

  @override
  ConsumerState<_ScannerSheet> createState() => _ScannerSheetState();
}

class _ScannerSheetState extends ConsumerState<_ScannerSheet> {
  bool _manual = false;

  /// Last problem (unknown code / stock) shown under the camera.
  String? _message;
  String? _unknownCode;
  int _messageCount = 0;

  /// Contract 1 (LA2): BarcodeScannerView → CartNotifier.addByBarcode.
  /// Returns true (green frame) on success, false (amber frame + shake) on
  /// any typed failure; the cart is unchanged on failure.
  Future<bool?> _onScan(String code) async {
    final l10n = context.l10n;
    final feedback = ref.read(feedbackProvider);
    try {
      await ref.read(cartProvider.notifier).addByBarcode(code);
      if (!mounted) return null;
      feedback.scanned();
      setState(() {
        _message = null;
        _unknownCode = null;
      });
      return true;
    } on Object catch (error) {
      feedback.error();
      if (mounted) {
        setState(() {
          _message = error.toUserMessage(l10n);
          // Unknown barcode: the owner gets an "Add this product" shortcut.
          _unknownCode = error is ProductNotFound ? error.barcode : null;
          _messageCount++;
        });
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final isOwner = ref.watch(
      currentUserProvider.select((u) => u?.isOwner ?? false),
    );
    final count = ref.watch(cartProvider.select((c) => c.itemCount));
    const onDark = Colors.white;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(
          context,
        ).textTheme.apply(bodyColor: onDark, displayColor: onDark),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Gaps.md,
          Gaps.sm,
          Gaps.md,
          Gaps.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.scannerTitle,
                    style: context.text.titleLarge?.copyWith(color: onDark),
                  ),
                ),
                _CartCounter(count: count),
              ],
            ),
            const SizedBox(height: Gaps.md),
            Expanded(child: BarcodeScannerView(onScan: _onScan)),
            const SizedBox(height: Gaps.sm),
            AnimatedSize(
              duration: context.motion.normal,
              curve: AppMotion.enter,
              child: _message == null
                  ? const SizedBox(width: double.infinity)
                  : ShakeOnChange(
                      trigger: _messageCount,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(Gaps.sm + Gaps.xs),
                        decoration: BoxDecoration(
                          color: tokens.warningContainer,
                          borderRadius: BorderRadius.circular(AppRadii.small),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Symbols.warning_rounded,
                              color: tokens.onWarningContainer,
                            ),
                            const SizedBox(width: Gaps.sm),
                            Expanded(
                              child: Text(
                                _message!,
                                style: TextStyle(
                                  color: tokens.onWarningContainer,
                                ),
                              ),
                            ),
                            if (isOwner && _unknownCode != null)
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: tokens.onWarningContainer,
                                ),
                                onPressed: () {
                                  final code = _unknownCode!;
                                  final router = GoRouter.of(context);
                                  Navigator.of(context).pop();
                                  unawaited(
                                    router.push(
                                      Uri(
                                        path: AppRoutes.productNew,
                                        queryParameters: {
                                          AppRoutes.barcodeParam: code,
                                        },
                                      ).toString(),
                                    ),
                                  );
                                },
                                child: Text(l10n.productAddThis),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: Gaps.sm),
            if (_manual)
              Theme(
                data: Theme.of(context),
                child: ManualBarcodeField(onSubmit: _onScan),
              )
            else
              Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Symbols.keyboard_rounded),
                    label: Text(l10n.scanManualChip),
                    onPressed: () => setState(() => _manual = true),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.done),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Cart count bubble that pulses whenever an item is added.
class _CartCounter extends StatelessWidget {
  const _CartCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubble = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gaps.md,
        vertical: Gaps.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Symbols.shopping_basket_rounded,
            color: scheme.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: Gaps.xs),
          Text(
            context.l10n.scanCartCount(count),
            style: AppTypography.tabular(
              context.text.labelLarge?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
    if (!context.motion.enabled || count == 0) return bubble;
    return bubble
        .animate(key: ValueKey(count))
        .scaleXY(
          begin: 1.15,
          end: 1,
          duration: context.motion.normal,
          curve: Curves.easeOutBack,
        );
  }
}
