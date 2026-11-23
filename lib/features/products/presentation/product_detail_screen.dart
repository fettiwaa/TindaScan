import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';
import 'package:tindascan/core/utils/formatters.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/core/utils/money.dart';
import 'package:tindascan/core/widgets/app_card.dart';
import 'package:tindascan/core/widgets/feedback_ui.dart';
import 'package:tindascan/core/widgets/motion.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/core/widgets/stock_pill.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/products/application/product_providers.dart';
import 'package:tindascan/features/products/domain/internal_code.dart';
import 'package:tindascan/features/products/domain/product_category.dart';
import 'package:tindascan/features/products/presentation/product_labels.dart';
import 'package:tindascan/features/products/presentation/product_tile.dart';
import 'package:tindascan/features/stock/presentation/stock_adjust_screen.dart';
import 'package:tindascan/shared/models/product.dart';

/// Product details page (phones). Staff see a read-only view.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context) =>
      ProductDetailView(productId: productId, embedded: false);
}

/// Detail content; also used as the right pane on tablets ([embedded]).
class ProductDetailView extends ConsumerWidget {
  const ProductDetailView({
    required this.productId,
    required this.embedded,
    super.key,
  });

  final String productId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId));
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: !embedded),
      body: AsyncValueView<Product?>(
        value: product,
        loading: const LoadingView(),
        onRetry: () => ref.invalidate(productByIdProvider(productId)),
        isEmpty: (p) => p == null,
        emptyMessage: context.l10n.errorNotFound,
        data: (p) => _Details(product: p!, hero: !embedded),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  const _Details({required this.product, required this.hero});

  final Product product;
  final bool hero;

  /// Archive is reversible, so it uses Undo instead of a confirm dialog.
  Future<void> _toggleArchive(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = ref.read(productEditControllerProvider.notifier);
    final archiving = product.isActive;
    final ok = await controller.setActive(product.id, active: !archiving);
    if (!context.mounted) return;
    if (!ok) {
      final error = ref.read(productEditControllerProvider).error;
      showAppSnackBar(
        context,
        (error ?? '').toUserMessage(l10n),
        type: SnackType.error,
      );
      return;
    }
    if (archiving) {
      showAppSnackBar(
        context,
        l10n.productArchivedSnack(product.name),
        actionLabel: l10n.undo,
        onAction: () => controller.setActive(product.id, active: true),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isOwner = ref.watch(
      currentUserProvider.select((u) => u?.isOwner ?? false),
    );
    final busy = ref.watch(
      productEditControllerProvider.select((s) => s.isLoading),
    );
    final now = ref.watch(clockProvider)();
    final expiry = product.expiryDate;
    final number = AppTypography.tabular(theme.textTheme.titleMedium);

    Widget valueRow(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Gaps.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
          Text(value, style: number?.copyWith(color: color)),
        ],
      ),
    );

    var order = 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Gaps.md, 0, Gaps.md, Gaps.xl),
      children: [
        Row(
          children: [
            ProductAvatar(product: product, size: 72, hero: hero),
            const SizedBox(width: Gaps.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: Gaps.xs),
                  Text(
                    ProductCategory.fromKey(product.category).label(l10n),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Gaps.sm),
                  StockPill(
                    stock: product.stockQty,
                    threshold: product.lowStockThreshold,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Gaps.lg),
        AppCard(
          child: Column(
            children: [
              valueRow(
                l10n.productPrice,
                Money.format(product.unitPriceCentavos),
              ),
              if (isOwner) ...[
                valueRow(
                  l10n.productCost,
                  Money.format(product.costPriceCentavos),
                ),
                valueRow(
                  l10n.productProfit,
                  Money.format(product.profitPerUnitCentavos),
                  color: product.profitPerUnitCentavos < 0
                      ? tokens.danger
                      : tokens.success,
                ),
              ],
            ],
          ),
        ).enterSection(context, order: order++),
        const SizedBox(height: Gaps.md),
        AppCard(
          child: Column(
            children: [
              valueRow(
                l10n.productThresholdLabel,
                '${product.lowStockThreshold}',
              ),
              if (expiry != null)
                valueRow(
                  product.isExpired(now)
                      ? l10n.productExpired
                      : l10n.productExpiryLabel,
                  AppFormat.date(context, expiry),
                  color: product.isExpired(now)
                      ? tokens.danger
                      : product.expiresWithin(now, 7)
                      ? tokens.warning
                      : null,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Gaps.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        InternalCode.isInternal(product.barcode)
                            ? l10n.productInternalCode
                            : l10n.productBarcodeLabel,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    SelectableText(
                      product.barcode,
                      style: AppTypography.mono(theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
              if (!product.isActive)
                valueRow(l10n.productArchivedBadge, '', color: tokens.warning),
            ],
          ),
        ).enterSection(context, order: order++),
        if (isOwner) ...[
          const SizedBox(height: Gaps.lg),
          PrimaryButton(
            key: const Key('adjust-stock'),
            label: l10n.productAdjustStock,
            icon: Symbols.inventory_rounded,
            onPressed: product.isActive
                ? () => showStockAdjustSheet(context, product)
                : null,
          ),
          const SizedBox(height: Gaps.sm),
          Wrap(
            spacing: Gaps.sm,
            runSpacing: Gaps.sm,
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.productEdit(product.id)),
                icon: const Icon(Symbols.edit_rounded),
                label: Text(l10n.edit),
              ),
              TextButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.productHistory(product.id)),
                icon: const Icon(Symbols.history_rounded),
                label: Text(l10n.productHistory),
              ),
              TextButton.icon(
                onPressed: busy ? null : () => _toggleArchive(context, ref),
                icon: Icon(
                  product.isActive
                      ? Symbols.archive_rounded
                      : Symbols.unarchive_rounded,
                ),
                label: Text(product.isActive ? l10n.archive : l10n.restore),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
