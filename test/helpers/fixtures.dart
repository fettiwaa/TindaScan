import 'package:tindascan/features/products/domain/product_category.dart';
import 'package:tindascan/shared/models/product.dart';

/// Builds a product for tests.
Product product({
  String id = 'p1',
  String barcode = '4800016644283',
  String name = 'Lucky Me Pancit Canton',
  int price = 1600,
  int cost = 1250,
  int stock = 10,
  int threshold = 3,
  bool active = true,
  DateTime? expiry,
  ProductCategory category = ProductCategory.noodles,
}) => Product(
  id: id,
  barcode: barcode,
  name: name,
  category: category.key,
  unitPriceCentavos: price,
  costPriceCentavos: cost,
  stockQty: stock,
  lowStockThreshold: threshold,
  isActive: active,
  expiryDate: expiry,
);
