import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';
import 'package:tindascan/core/utils/formatters.dart';
import 'package:tindascan/core/utils/money.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/motion.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/core/widgets/success_check.dart';
import 'package:tindascan/features/sales/presentation/receipt_text.dart';
import 'package:tindascan/features/settings/application/settings_providers.dart';
import 'package:tindascan/shared/models/sale.dart';

/// Sale complete: animated check, then a paper-style receipt.
class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({required this.sale, super.key});

  final Sale sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final storeName = ref.watch(
      storeSettingsProvider.select((s) => s.value?.storeName ?? l10n.appTitle),
    );
    final created = sale.createdAt;
    final dateText = created == null
        ? ''
        : AppFormat.dateTime(context, created);

    void share() => SharePlus.instance.share(
      ShareParams(
        subject: l10n.receiptNo(sale.receiptNo),
        text: buildReceiptText(
          sale: sale,
          storeName: storeName,
          dateText: dateText,
          l10n: l10n,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.receiptTitle),
        actions: [
          IconButton(
            tooltip: l10n.close,
            icon: const Icon(Symbols.close_rounded),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.lg),
              children: [
                SuccessCheck(semanticLabel: l10n.receiptSaleComplete),
                const SizedBox(height: Gaps.sm),
                Text(
                  l10n.receiptSaleComplete,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: Gaps.lg),
                if (sale.offline)
                  MessageBanner(text: l10n.receiptOffline, isError: false),
                _PaperReceipt(
                  sale: sale,
                  storeName: storeName,
                  dateText: dateText,
                ).enterSection(context, order: 3),
                const SizedBox(height: Gaps.lg),
                SecondaryButton(
                  label: l10n.share,
                  icon: Symbols.share_rounded,
                  onPressed: share,
                ),
                const SizedBox(height: Gaps.sm),
                PrimaryButton(
                  key: const Key('new-sale'),
                  label: l10n.receiptNewSale,
                  icon: Symbols.add_shopping_cart_rounded,
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperReceipt extends StatelessWidget {
  const _PaperReceipt({
    required this.sale,
    required this.storeName,
    required this.dateText,
  });

  final Sale sale;
  final String storeName;
  final String dateText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final mono = AppTypography.mono(
      theme.textTheme.bodyMedium?.copyWith(color: tokens.onPaper),
    );
    final monoBold = mono.copyWith(fontWeight: AppTypography.semibold);
    final monoLarge = AppTypography.mono(
      theme.textTheme.titleLarge?.copyWith(color: tokens.onPaper),
    );

    Widget row(String left, String right, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Gaps.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(left, style: style ?? mono)),
          const SizedBox(width: Gaps.sm),
          Text(right, style: style ?? mono),
        ],
      ),
    );

    Widget dashes() => Padding(
      padding: const EdgeInsets.symmetric(vertical: Gaps.sm),
      child: Text(
        '- ' * 40,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: mono.copyWith(color: tokens.cardOutline),
      ),
    );

    return ClipPath(
      clipper: const PerforatedEdgeClipper(),
      child: Container(
        color: tokens.paper,
        padding: const EdgeInsets.fromLTRB(Gaps.lg, Gaps.xl, Gaps.lg, Gaps.xl),
        child: DecoratedBox(
          decoration: const BoxDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                storeName,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: tokens.onPaper,
                ),
              ),
              const SizedBox(height: Gaps.xs),
              Text(
                l10n.receiptNo(sale.receiptNo),
                textAlign: TextAlign.center,
                style: mono,
              ),
              if (dateText.isNotEmpty)
                Text(dateText, textAlign: TextAlign.center, style: mono),
              dashes(),
              for (final item in sale.items) ...[
                Text(item.name, style: mono),
                row(
                  '  ${item.qty} × ${Money.format(item.unitPriceCentavos)}',
                  Money.format(item.subtotalCentavos),
                ),
              ],
              dashes(),
              row(
                l10n.sellTotal,
                Money.format(sale.totalCentavos),
                style: monoLarge,
              ),
              row(l10n.receiptCash, Money.format(sale.amountTenderedCentavos)),
              row(
                l10n.paymentChange,
                Money.format(sale.changeCentavos),
                style: monoBold,
              ),
              dashes(),
              Text(
                l10n.receiptCashier(sale.cashierName),
                textAlign: TextAlign.center,
                style: mono,
              ),
              const SizedBox(height: Gaps.xs),
              Text(
                l10n.receiptThanks,
                textAlign: TextAlign.center,
                style: mono,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paper look: zig-zag (perforated) top and bottom edges.
class PerforatedEdgeClipper extends CustomClipper<Path> {
  const PerforatedEdgeClipper({this.tooth = 10});

  /// Width of one zig-zag tooth.
  final double tooth;

  @override
  Path getClip(Size size) {
    final half = tooth / 2;
    final path = Path()..moveTo(0, half);
    for (var x = 0.0; x < size.width; x += tooth) {
      path
        ..lineTo(x + half, 0)
        ..lineTo(x + tooth, half);
    }
    path.lineTo(size.width, size.height - half);
    for (var x = size.width; x > 0; x -= tooth) {
      path
        ..lineTo(x - half, size.height)
        ..lineTo(x - tooth, size.height - half);
    }
    return path..close();
  }

  @override
  bool shouldReclip(PerforatedEdgeClipper oldClipper) =>
      oldClipper.tooth != tooth;
}
