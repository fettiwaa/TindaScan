import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/features/products/domain/product_category.dart';
import 'package:tindascan/features/products/domain/product_validators.dart';

/// Localized category names.
extension ProductCategoryLabel on ProductCategory {
  String label(AppLocalizations l10n) => switch (this) {
    ProductCategory.beverages => l10n.categoryBeverages,
    ProductCategory.snacks => l10n.categorySnacks,
    ProductCategory.noodles => l10n.categoryNoodles,
    ProductCategory.cannedGoods => l10n.categoryCannedGoods,
    ProductCategory.condiments => l10n.categoryCondiments,
    ProductCategory.riceAndGrains => l10n.categoryRiceGrains,
    ProductCategory.dairy => l10n.categoryDairy,
    ProductCategory.bread => l10n.categoryBread,
    ProductCategory.personalCare => l10n.categoryPersonalCare,
    ProductCategory.household => l10n.categoryHousehold,
    ProductCategory.frozen => l10n.categoryFrozen,
    ProductCategory.others => l10n.categoryOthers,
  };
}

/// Localized product-form validation messages.
extension ProductFieldErrorText on ProductFieldError? {
  String? toText(AppLocalizations l10n) => switch (this) {
    null => null,
    ProductFieldError.required => l10n.fieldRequired,
    ProductFieldError.tooLong => l10n.fieldTooLong(AppConstants.maxNameLength),
    ProductFieldError.invalidBarcode => l10n.fieldInvalidBarcode,
    ProductFieldError.invalidMoney => l10n.fieldInvalidMoney,
    ProductFieldError.invalidQuantity => l10n.fieldInvalidQuantity(
      AppConstants.maxQuantity,
    ),
    ProductFieldError.costAbovePrice => l10n.productPriceBelowCost,
  };
}
