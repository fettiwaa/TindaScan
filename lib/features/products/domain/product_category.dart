/// Fixed sari-sari categories. The stored value is the stable [key]; labels
/// are localized in the UI (see `product_labels.dart`).
enum ProductCategory {
  beverages('beverages'),
  snacks('snacks'),
  noodles('noodles'),
  cannedGoods('canned_goods'),
  condiments('condiments'),
  riceAndGrains('rice_grains'),
  dairy('dairy'),
  bread('bread'),
  personalCare('personal_care'),
  household('household'),
  frozen('frozen'),
  others('others');

  const ProductCategory(this.key);

  final String key;

  /// Unknown or empty keys map to [others].
  static ProductCategory fromKey(String? key) => ProductCategory.values
      .firstWhere((c) => c.key == key, orElse: () => others);
}
