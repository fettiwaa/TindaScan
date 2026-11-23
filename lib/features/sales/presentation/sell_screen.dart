import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';
import 'package:tindascan/core/utils/money.dart';
import 'package:tindascan/core/widgets/animated_counter.dart';
import 'package:tindascan/core/widgets/feedback_ui.dart';
import 'package:tindascan/core/widgets/form_controls.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/motion.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/features/products/presentation/product_tile.dart';
import 'package:tindascan/features/sales/application/cart_notifier.dart';
import 'package:tindascan/features/sales/application/lost_sales_log.dart';
import 'package:tindascan/features/sales/application/product_suggestions.dart';
import 'package:tindascan/features/sales/domain/cart.dart';
import 'package:tindascan/features/sales/presentation/payment_sheet.dart';
import 'package:tindascan/features/scanner/presentation/scanner_sheet.dart';
import 'package:tindascan/features/settings/application/app_preferences.dart';
import 'package:tindascan/shared/models/product.dart';

/// The hero screen: search or scan to build the cart, then Charge.
class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _showFailure(Failure failure) {
    ref.read(feedbackProvider).error();
    showAppSnackBar(
      context,
      failure.toUserMessage(context.l10n),
      type: SnackType.warning,
    );
  }

  void _pickSuggestion(Product product) {
    final failure = ref.read(cartProvider.notifier).add(product);
    if (failure != null) {
      _showFailure(failure);
    } else {
      ref.read(feedbackProvider).light();
    }
    _search.clear();
    _debounce?.cancel();
    setState(() => _query = '');
    FocusScope.of(context).unfocus();
  }

  Future<void> _charge() async {
    final router = GoRouter.of(context);
    final sale = await showPaymentSheet(context);
    if (sale != null && mounted) {
      unawaited(router.push(AppRoutes.sellReceipt, extra: sale));
    }
  }

  void _clearCart() {
    final l10n = context.l10n;
    final notifier = ref.read(cartProvider.notifier);
    final previous = ref.read(cartProvider);
    notifier.clear();
    showAppSnackBar(
      context,
      l10n.cartCleared,
      actionLabel: l10n.undo,
      onAction: () => notifier.restore(previous),
    );
  }

  Future<void> _confirmLeave() async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final discard = await showConfirmDialog(
      context,
      title: l10n.sellDiscardTitle,
      message: l10n.sellDiscardMessage,
      confirmLabel: l10n.discard,
      destructive: true,
    );
    if (discard) {
      ref.read(cartProvider.notifier).clear();
      unawaited(navigator.maybePop());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cart = ref.watch(cartProvider);

    return PopScope(
      // Respect the back button, but never lose a cart silently.
      canPop: cart.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.sellTitle),
          actions: [
            if (!cart.isEmpty)
              IconButton(
                tooltip: l10n.sellClearCart,
                icon: const Icon(Symbols.remove_shopping_cart_rounded),
                onPressed: _clearCart,
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('scan-fab'),
          onPressed: () => showScannerSheet(context),
          icon: const Icon(Symbols.barcode_scanner_rounded),
          label: Text(l10n.sellScan),
        ),
        body: Column(
          children: [
            const _LostSalesBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gaps.md, 0, Gaps.md, Gaps.sm),
              child: TextField(
                key: const Key('sell-search'),
                controller: _search,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.sellSearchHint,
                  prefixIcon: const Icon(Symbols.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: l10n.scannerTitle,
                    icon: const Icon(Symbols.barcode_scanner_rounded),
                    onPressed: () => showScannerSheet(context),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: context.motion.fast,
                child: _query.isEmpty
                    ? _CartList(
                        key: const ValueKey('cart'),
                        cart: cart,
                        onFailure: _showFailure,
                        onScan: () => showScannerSheet(context),
                      )
                    : _Suggestions(
                        key: ValueKey('q-$_query'),
                        query: _query,
                        onPick: _pickSuggestion,
                      ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: AnimatedSize(
          duration: context.motion.normal,
          curve: AppMotion.enter,
          child: cart.isEmpty
              ? const SizedBox(width: double.infinity)
              : _SummaryCard(cart: cart, onCharge: _charge),
        ),
      ),
    );
  }
}

/// Offline sales the server rejected on sync (see `LostSalesLog`). Stays
/// until the cashier confirms they were re-entered.
class _LostSalesBanner extends ConsumerWidget {
  const _LostSalesBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lost = ref.watch(lostSalesProvider).value ?? const <LostSale>[];
    if (lost.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final receipts = lost
        .map((s) => '${s.receiptNo} (${Money.format(s.totalCentavos)})')
        .join(', ');
    return Padding(
      key: const Key('lost-sales-banner'),
      padding: const EdgeInsets.fromLTRB(Gaps.md, 0, Gaps.md, Gaps.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MessageBanner(text: l10n.lostSalesBanner(receipts)),
          TextButton(
            onPressed: () => ref.read(lostSalesProvider.notifier).dismissAll(),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.query, required this.onPick, super.key});

  final String query;
  final ValueChanged<Product> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final results = ref.watch(productSuggestionsProvider(query));
    return AsyncValueView<List<Product>>(
      value: results,
      loading: const SkeletonList(itemCount: 4),
      onRetry: () => ref.invalidate(productSuggestionsProvider(query)),
      isEmpty: (list) => list.isEmpty,
      emptyMessage: l10n.productsEmpty,
      emptyIcon: Symbols.search_off_rounded,
      data: (list) => ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final product = list[index];
          final out = product.stockQty <= 0;
          return ProductTile(
            key: Key('suggestion-${product.id}'),
            product: product,
            hero: false,
            onTap: out ? null : () => onPick(product),
          ).staggerIn(context, index);
        },
      ),
    );
  }
}

class _CartList extends ConsumerWidget {
  const _CartList({
    required this.cart,
    required this.onFailure,
    required this.onScan,
    super.key,
  });

  final Cart cart;
  final ValueChanged<Failure> onFailure;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (cart.isEmpty) {
      return EmptyState(
        message: l10n.sellCartEmpty,
        icon: Symbols.shopping_basket_rounded,
        actionLabel: l10n.sellEmptyAction,
        onAction: onScan,
      );
    }
    return SlidableAutoCloseBehavior(
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: Gaps.xxl * 2),
        itemCount: cart.lines.length,
        separatorBuilder: (_, _) =>
            const Divider(indent: Gaps.md, endIndent: Gaps.md),
        itemBuilder: (context, index) => _CartLineTile(
          key: ValueKey(cart.lines[index].product.id),
          line: cart.lines[index],
          onFailure: onFailure,
        ),
      ),
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  const _CartLineTile({required this.line, required this.onFailure, super.key});

  final CartLine line;
  final ValueChanged<Failure> onFailure;

  void _remove(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifier = ref.read(cartProvider.notifier);
    final previous = ref.read(cartProvider);
    notifier.remove(line.product.id);
    showAppSnackBar(
      context,
      l10n.cartRemoved(line.product.name),
      actionLabel: l10n.undo,
      onAction: () => notifier.restore(previous),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final product = line.product;
    final tile = Slidable(
      key: ValueKey('slide-${product.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.3,
        dismissible: DismissiblePane(onDismissed: () => _remove(context, ref)),
        children: [
          SlidableAction(
            onPressed: (_) => _remove(context, ref),
            backgroundColor: context.tokens.dangerContainer,
            foregroundColor: context.tokens.onDangerContainer,
            icon: Symbols.delete_rounded,
            label: l10n.sellRemove,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gaps.md,
          vertical: Gaps.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: Gaps.xxs),
                  Text(
                    Money.format(line.subtotalCentavos),
                    style: AppTypography.tabular(theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Gaps.sm),
            QuantityStepper(
              value: line.qty,
              max: product.stockQty,
              valueKey: Key('qty-${product.id}'),
              onChanged: (qty) {
                if (qty <= 0) {
                  _remove(context, ref);
                  return;
                }
                final failure = ref
                    .read(cartProvider.notifier)
                    .setQuantity(product, qty);
                if (failure != null) {
                  onFailure(failure);
                } else {
                  ref.read(feedbackProvider).light();
                }
              },
            ),
          ],
        ),
      ),
    );
    if (!context.motion.enabled) return tile;
    // Subtle scale-in when a line is added (keyed by product, so it plays
    // once per line, not on every rebuild).
    return tile
        .animate()
        .fadeIn(duration: context.motion.normal)
        .scaleXY(begin: 0.96, end: 1, curve: AppMotion.enter);
  }
}

/// Sticky summary: item count, large animated total and the Charge button.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.cart, required this.onCharge});

  final Cart cart;
  final VoidCallback onCharge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: context.tokens.cardOutline)),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.large),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Gaps.md,
            Gaps.md,
            Gaps.md,
            Gaps.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.sellTotal, style: theme.textTheme.labelLarge),
                        Text(
                          l10n.sellItems(cart.itemCount),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: AnimatedCounter.money(
                        key: const Key('cart-total'),
                        centavos: cart.totalCentavos,
                        style: theme.textTheme.displaySmall,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gaps.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('charge-button'),
                  onPressed: onCharge,
                  icon: const Icon(Symbols.payments_rounded),
                  label: Text(
                    l10n.sellCharge(Money.format(cart.totalCentavos)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
