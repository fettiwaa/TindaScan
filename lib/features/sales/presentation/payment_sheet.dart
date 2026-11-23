import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/connectivity/connectivity_providers.dart';
import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';
import 'package:tindascan/core/utils/money.dart';
import 'package:tindascan/core/widgets/animated_counter.dart';
import 'package:tindascan/core/widgets/feedback_ui.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/features/sales/application/cart_notifier.dart';
import 'package:tindascan/features/sales/application/checkout_service.dart';
import 'package:tindascan/features/sales/domain/payment.dart';
import 'package:tindascan/features/settings/application/app_preferences.dart';
import 'package:tindascan/shared/models/sale.dart';

/// Opens the cash payment sheet. Resolves to the recorded sale, or null if
/// the cashier closed the sheet.
Future<Sale?> showPaymentSheet(BuildContext context) =>
    showAppBottomSheet<Sale>(context, builder: (_) => const PaymentSheet());

/// Big amount-tendered display, quick-cash chips, live change and Confirm.
class PaymentSheet extends ConsumerStatefulWidget {
  const PaymentSheet({super.key});

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  final _tendered = TextEditingController();

  /// True while CheckoutService is recording the sale (Confirm disabled).
  bool _submitting = false;

  /// Last checkout failure, shown above the amount field.
  Object? _error;

  @override
  void dispose() {
    _tendered.dispose();
    super.dispose();
  }

  void _setAmount(int centavos) {
    _tendered.text = Money.toInput(centavos);
    setState(() {});
  }

  Future<void> _confirm() async {
    final tendered = Money.tryParse(_tendered.text);
    if (tendered == null) return;
    final navigator = Navigator.of(context);
    final feedback = ref.read(feedbackProvider);
    final service = ref.read(checkoutServiceProvider);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final sale = await service.checkout(ref.read(cartProvider), tendered);
      feedback.success();
      if (mounted) navigator.pop(sale);
    } on Object catch (error) {
      feedback.error();
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cart = ref.watch(cartProvider);
    final online = ref.watch(isOnlineProvider).value ?? true;
    final total = cart.totalCentavos;
    final tendered = Money.tryParse(_tendered.text);
    final change = tendered == null
        ? null
        : Payment.change(totalCentavos: total, tenderedCentavos: tendered);
    final submitting = _submitting;
    final short = tendered != null && change == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.paymentTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: Gaps.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                '${l10n.sellTotal} · ${l10n.sellItems(cart.itemCount)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: Gaps.sm),
            Text(
              Money.format(total),
              key: const Key('payment-total'),
              style: AppTypography.tabular(theme.textTheme.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: Gaps.lg),
        if (_error != null) MessageBanner(text: _error!.toUserMessage(l10n)),
        if (!online)
          MessageBanner(text: l10n.paymentOfflineNote, isError: false),
        TextField(
          key: const Key('tendered-field'),
          controller: _tendered,
          autofocus: true,
          enabled: !submitting,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (_) => setState(() {}),
          style: AppTypography.tabular(theme.textTheme.displaySmall),
          decoration: InputDecoration(
            labelText: l10n.paymentTendered,
            prefixText: '₱ ',
            prefixStyle: AppTypography.tabular(theme.textTheme.displaySmall),
            errorText: short ? l10n.errorInsufficientPayment : null,
          ),
        ),
        const SizedBox(height: Gaps.md),
        Wrap(
          spacing: Gaps.sm,
          runSpacing: Gaps.sm,
          children: [
            for (final amount in Payment.quickAmounts(total))
              ActionChip(
                label: Text(
                  amount == total
                      ? l10n.paymentExact
                      : Money.format(amount).replaceAll('.00', ''),
                  style: AppTypography.tabular(theme.textTheme.labelLarge),
                ),
                onPressed: submitting ? null : () => _setAmount(amount),
              ),
          ],
        ),
        const SizedBox(height: Gaps.lg),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Gaps.md,
            vertical: Gaps.sm + Gaps.xs,
          ),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadii.medium),
          ),
          child: Row(
            children: [
              Text(l10n.paymentChange, style: theme.textTheme.titleMedium),
              const SizedBox(width: Gaps.sm),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: AnimatedCounter.money(
                    key: const Key('change-amount'),
                    centavos: change ?? 0,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gaps.lg),
        PrimaryButton(
          key: const Key('confirm-sale'),
          label: l10n.paymentConfirm,
          icon: Icons.check_rounded,
          isLoading: submitting,
          // Disabled until the cash covers the total, and while submitting
          // (prevents double charging).
          onPressed: change == null || cart.isEmpty ? null : _confirm,
        ),
      ],
    );
  }
}
