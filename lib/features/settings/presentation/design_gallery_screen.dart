import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_theme.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/utils/money.dart';
import 'package:tindascan/core/widgets/animated_counter.dart';
import 'package:tindascan/core/widgets/app_card.dart';
import 'package:tindascan/core/widgets/feedback_ui.dart';
import 'package:tindascan/core/widgets/form_controls.dart';
import 'package:tindascan/core/widgets/message_banner.dart';
import 'package:tindascan/core/widgets/primary_button.dart';
import 'package:tindascan/core/widgets/stat_card.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/core/widgets/stock_pill.dart';
import 'package:tindascan/core/widgets/success_check.dart';

/// Debug-only showcase of every core component in light and dark themes,
/// to keep the design consistent as screens evolve.
class DesignGalleryScreen extends StatefulWidget {
  const DesignGalleryScreen({super.key});

  @override
  State<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = _dark ? AppTheme.dark() : AppTheme.light();
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(l10n.designGalleryTitle),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: Gaps.sm),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Symbols.light_mode_rounded),
                    tooltip: l10n.settingsThemeLight,
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Symbols.dark_mode_rounded),
                    tooltip: l10n.settingsThemeDark,
                  ),
                ],
                selected: {_dark},
                onSelectionChanged: (s) => setState(() => _dark = s.first),
              ),
            ),
          ],
        ),
        body: const DesignGalleryBody(),
      ),
    );
  }
}

/// Gallery content (also rendered by golden tests).
class DesignGalleryBody extends StatefulWidget {
  const DesignGalleryBody({super.key});

  @override
  State<DesignGalleryBody> createState() => _DesignGalleryBodyState();
}

class _DesignGalleryBodyState extends State<DesignGalleryBody> {
  int _qty = 2;
  int _total = 12345;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(Gaps.md),
      children: [
        const SectionHeader(title: 'Typography', padding: EdgeInsets.zero),
        Text('₱1,234.50', style: text.displaySmall),
        Text('Title', style: text.titleLarge),
        Text('Body text for descriptions.', style: text.bodyLarge),
        Text('LABEL', style: text.labelLarge),
        const SectionHeader(title: 'StatCard', count: 3),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: l10n.dashboardTodaySales,
                value: _total,
                format: Money.format,
                emphasis: true,
              ),
            ),
            const SizedBox(width: Gaps.sm),
            Expanded(
              child: StatCard(
                label: l10n.dashboardTransactions,
                icon: Symbols.receipt_long_rounded,
                value: 18,
              ),
            ),
          ],
        ),
        const SectionHeader(title: 'StockPill'),
        const Wrap(
          spacing: Gaps.sm,
          children: [
            StockPill(stock: 24, threshold: 5),
            StockPill(stock: 3, threshold: 5),
            StockPill(stock: 0, threshold: 5),
          ],
        ),
        const SectionHeader(title: 'AnimatedCounter + QuantityStepper'),
        Row(
          children: [
            AnimatedCounter.money(centavos: _total),
            const Spacer(),
            QuantityStepper(
              value: _qty,
              onChanged: (v) => setState(() {
                _qty = v;
                _total = 1600 * v;
              }),
            ),
          ],
        ),
        const SectionHeader(title: 'Buttons'),
        PrimaryButton(
          label: l10n.paymentConfirm,
          icon: Symbols.check_rounded,
          isLoading: _loading,
          onPressed: () => setState(() => _loading = !_loading),
        ),
        const SizedBox(height: Gaps.sm),
        SecondaryButton(
          label: l10n.share,
          icon: Symbols.share_rounded,
          onPressed: () => showAppSnackBar(
            context,
            l10n.stockSaved,
            type: SnackType.success,
            actionLabel: l10n.undo,
            onAction: () {},
          ),
        ),
        const SectionHeader(title: 'AppTextField'),
        AppTextField(label: l10n.productNameLabel, icon: Symbols.label_rounded),
        const SectionHeader(title: 'AppCard + MessageBanner'),
        AppCard(onTap: () {}, child: Text(l10n.productsSelectHint)),
        const SizedBox(height: Gaps.sm),
        MessageBanner(text: l10n.paymentOfflineNote, isError: false),
        const SectionHeader(title: 'EmptyState / SuccessCheck'),
        SizedBox(
          height: 260,
          child: EmptyState(
            message: l10n.sellCartEmpty,
            icon: Symbols.shopping_basket_rounded,
            actionLabel: l10n.sellEmptyAction,
            onAction: () {},
          ),
        ),
        const SuccessCheck(),
        const SectionHeader(title: 'SkeletonList'),
        const SizedBox(height: 180, child: SkeletonList(itemCount: 3)),
        const SectionHeader(title: 'Bottom sheet'),
        OutlinedButton(
          onPressed: () => showAppBottomSheet<void>(
            context,
            builder: (_) => Text(l10n.stockAdjustTitle, style: text.titleLarge),
          ),
          child: Text(l10n.stockAdjustTitle),
        ),
        const SizedBox(height: Gaps.xl),
      ],
    );
  }
}
