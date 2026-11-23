import 'package:flutter/material.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';
import 'package:tindascan/core/utils/money.dart';
import 'package:tindascan/core/widgets/stock_pill.dart';
import 'package:tindascan/features/products/domain/product_category.dart';
import 'package:tindascan/shared/models/product.dart';

/// Muted color per category, used only for the small avatar/dot.
Color categoryColor(ProductCategory category, Brightness brightness) {
  const hues = <ProductCategory, double>{
    ProductCategory.beverages: 200,
    ProductCategory.snacks: 30,
    ProductCategory.noodles: 45,
    ProductCategory.cannedGoods: 0,
    ProductCategory.condiments: 15,
    ProductCategory.riceAndGrains: 60,
    ProductCategory.dairy: 220,
    ProductCategory.bread: 35,
    ProductCategory.personalCare: 280,
    ProductCategory.household: 170,
    ProductCategory.frozen: 190,
    ProductCategory.others: 140,
  };
  final hue = hues[category] ?? 140;
  return brightness == Brightness.light
      ? HSLColor.fromAHSL(1, hue, 0.45, 0.88).toColor()
      : HSLColor.fromAHSL(1, hue, 0.30, 0.28).toColor();
}

/// Rounded letter avatar tinted by category. With [hero] it flies from
/// the list to the detail screen.
class ProductAvatar extends StatelessWidget {
  const ProductAvatar({
    required this.product,
    this.size = AppSizes.avatar,
    this.hero = true,
    super.key,
  });

  final Product product;
  final double size;
  final bool hero;

  static String heroTag(String productId) => 'product-avatar-$productId';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = ProductCategory.fromKey(product.category);
    final trimmed = product.name.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: categoryColor(category, theme.brightness),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        letter,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: size * 0.42,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
    if (!hero || product.id.isEmpty) return ExcludeSemantics(child: avatar);
    return ExcludeSemantics(
      child: Hero(tag: heroTag(product.id), child: avatar),
    );
  }
}

/// Product list row: avatar, name, price and a stock pill.
class ProductTile extends StatelessWidget {
  const ProductTile({
    required this.product,
    this.onTap,
    this.trailing,
    this.selected = false,
    this.hero = true,
    super.key,
  });

  final Product product;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool selected;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      selected: selected,
      selectedTileColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.4,
      ),
      leading: ProductAvatar(product: product, hero: hero),
      title: Text(
        product.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Text(
        product.isActive
            ? Money.format(product.unitPriceCentavos)
            : '${Money.format(product.unitPriceCentavos)} · ${l10n.productArchivedBadge}',
        style: AppTypography.tabular(theme.textTheme.bodyMedium),
      ),
      trailing:
          trailing ??
          StockPill(
            stock: product.stockQty,
            threshold: product.lowStockThreshold,
          ),
    );
  }
}
