import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';
import 'package:tindascan/core/widgets/feedback_ui.dart';
import 'package:tindascan/core/widgets/form_controls.dart';
import 'package:tindascan/core/widgets/form_page.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/core/widgets/stock_pill.dart';
import 'package:tindascan/features/products/application/product_providers.dart';
import 'package:tindascan/features/products/domain/product_validators.dart';
import 'package:tindascan/features/products/presentation/product_labels.dart';
import 'package:tindascan/features/stock/application/stock_controllers.dart';
import 'package:tindascan/features/stock/domain/restock.dart';
import 'package:tindascan/shared/models/product.dart';

/// Opens the stock adjustment as a bottom sheet (quick action). Resolves
/// to true when stock was changed.
Future<bool> showStockAdjustSheet(
  BuildContext context,
  Product product, {
  AdjustmentMode mode = AdjustmentMode.restock,
  int? suggestedQty,
}) async =>
    await showAppBottomSheet<bool>(
      context,
      builder: (_) => StockAdjustForm(
        product: product,
        initialMode: mode,
        suggestedQty: suggestedQty,
        onDone: (sheetContext) => Navigator.of(sheetContext).pop(true),
      ),
    ) ??
    false;

/// Full-screen version (deep links: `/products/:id/stock`).
class StockAdjustScreen extends ConsumerWidget {
  const StockAdjustScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId));
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.stockAdjustTitle)),
      body: AsyncValueView<Product?>(
        value: product,
        onRetry: () => ref.invalidate(productByIdProvider(productId)),
        isEmpty: (p) => p == null,
        emptyMessage: context.l10n.errorNotFound,
        data: (p) => FormPage(
          children: [
            StockAdjustForm(
              key: ValueKey(p!.id),
              product: p,
              onDone: (context) => GoRouter.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Restock (+), damaged/spoiled (−) or count correction, with a note.
class StockAdjustForm extends ConsumerStatefulWidget {
  const StockAdjustForm({
    required this.product,
    required this.onDone,
    this.initialMode = AdjustmentMode.restock,
    this.suggestedQty,
    super.key,
  });

  final Product product;
  final void Function(BuildContext context) onDone;
  final AdjustmentMode initialMode;

  /// Prefills the quantity (e.g. from the suggested restock list).
  final int? suggestedQty;

  @override
  ConsumerState<StockAdjustForm> createState() => _StockAdjustFormState();
}

class _StockAdjustFormState extends ConsumerState<StockAdjustForm> {
  final _formKey = GlobalKey<FormState>();
  late final _qty = TextEditingController(
    text: widget.suggestedQty == null ? '' : '${widget.suggestedQty}',
  );
  final _note = TextEditingController();
  late AdjustmentMode _mode = widget.initialMode;

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  int? get _change {
    final input = int.tryParse(_qty.text.trim());
    if (input == null) return null;
    return StockAdjustment.qtyChange(
      mode: _mode,
      input: input,
      currentStock: widget.product.stockQty,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final change = _change;
    final l10n = context.l10n;
    if (change == null || change == 0) {
      showAppSnackBar(context, l10n.stockNoChange, type: SnackType.warning);
      return;
    }
    final ok = await ref
        .read(stockAdjustControllerProvider.notifier)
        .adjust(
          productId: widget.product.id,
          mode: _mode,
          qtyChange: change,
          note: _note.text,
        );
    if (ok && mounted) {
      showAppSnackBar(context, l10n.stockSaved, type: SnackType.success);
      widget.onDone(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = ref.watch(stockAdjustControllerProvider);
    final product = widget.product;
    final change = _change;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(product.name, style: theme.textTheme.titleLarge),
        const SizedBox(height: Gaps.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: StockPill(
            stock: product.stockQty,
            threshold: product.lowStockThreshold,
          ),
        ),
        const SizedBox(height: Gaps.md),
        if (state case AsyncError(:final error))
          MessageBanner(text: error.toUserMessage(l10n)),
        SegmentedButton<AdjustmentMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: AdjustmentMode.restock,
              icon: const Icon(Symbols.add_rounded),
              label: Text(l10n.stockTypeRestock),
            ),
            ButtonSegment(
              value: AdjustmentMode.spoilage,
              icon: const Icon(Symbols.remove_rounded),
              label: Text(l10n.stockTypeSpoilage),
            ),
            ButtonSegment(
              value: AdjustmentMode.correction,
              icon: const Icon(Symbols.tune_rounded),
              label: Text(l10n.stockTypeAdjustment),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const FieldGap(),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                key: const Key('stock-qty'),
                controller: _qty,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                style: AppTypography.tabular(theme.textTheme.titleLarge),
                label: _mode == AdjustmentMode.correction
                    ? l10n.stockCorrectionLabel
                    : l10n.stockQuantityLabel,
                validator: (v) => ProductValidators.quantity(
                  v,
                  allowZero: _mode == AdjustmentMode.correction,
                ).toText(l10n),
              ),
              const FieldGap(),
              AppTextField(
                controller: _note,
                maxLength: AppConstants.maxNoteLength,
                label: l10n.stockNoteLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: Gaps.sm),
        AnimatedOpacity(
          opacity: change != null && change != 0 ? 1 : 0,
          duration: context.motion.fast,
          child: Text(
            l10n.stockAfter(product.stockQty + (change ?? 0)),
            style: AppTypography.tabular(theme.textTheme.titleMedium),
          ),
        ),
        const SizedBox(height: Gaps.lg),
        PrimaryButton(
          key: const Key('stock-save'),
          label: l10n.save,
          isLoading: state.isLoading,
          onPressed: _save,
        ),
      ],
    );
  }
}
