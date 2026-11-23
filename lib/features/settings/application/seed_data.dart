import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/features/products/domain/product_category.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/repositories/product_repository.dart';

/// Typical sari-sari items for demos and testing. Barcodes use the PH GS1
/// prefix (480) with valid EAN-13 check digits; they are samples and may not
/// match the real retail barcodes of these items.
List<Product> sampleProducts({DateTime? now}) {
  final today = now ?? DateTime.now();
  DateTime inDays(int days) => today.add(Duration(days: days));
  Product p(
    String barcode,
    String name,
    ProductCategory category,
    int price,
    int cost,
    int stock, {
    int threshold = 5,
    DateTime? expiry,
  }) => Product(
    id: '',
    barcode: barcode,
    name: name,
    category: category.key,
    unitPriceCentavos: price,
    costPriceCentavos: cost,
    stockQty: stock,
    lowStockThreshold: threshold,
    expiryDate: expiry,
  );

  return [
    p(
      '4800016644283',
      'Lucky Me Pancit Canton Original 60g',
      ProductCategory.noodles,
      1600,
      1250,
      48,
      threshold: 10,
    ),
    p(
      '4800036020913',
      'Payless Xtra Big Pancit Canton 130g',
      ProductCategory.noodles,
      2200,
      1800,
      24,
      threshold: 6,
    ),
    p(
      '4800194104104',
      'Bear Brand Powdered Milk 33g',
      ProductCategory.dairy,
      1300,
      1050,
      36,
      threshold: 8,
    ),
    p(
      '4801361001219',
      'Kopiko Black 3-in-1 Coffee 30g',
      ProductCategory.beverages,
      900,
      700,
      60,
      threshold: 12,
    ),
    p(
      '4800388040102',
      'Nescafe Classic Stick 2g',
      ProductCategory.beverages,
      300,
      220,
      4,
      threshold: 10,
    ),
    p(
      '4800016251238',
      'Coca-Cola Mismo 290ml',
      ProductCategory.beverages,
      2000,
      1600,
      24,
      threshold: 6,
    ),
    p(
      '4800024345707',
      'Argentina Corned Beef 150g',
      ProductCategory.cannedGoods,
      4500,
      3800,
      12,
      threshold: 4,
    ),
    p(
      '4800160228117',
      'Century Tuna Flakes in Oil 155g',
      ProductCategory.cannedGoods,
      3800,
      3200,
      3,
      threshold: 4,
    ),
    p(
      '4800503011253',
      'Ligo Sardines in Tomato Sauce 155g',
      ProductCategory.cannedGoods,
      2600,
      2150,
      18,
      threshold: 6,
    ),
    p(
      '4800004000121',
      'Datu Puti Soy Sauce 200ml',
      ProductCategory.condiments,
      1900,
      1550,
      10,
    ),
    p(
      '4801800003019',
      'Silver Swan Vinegar 200ml',
      ProductCategory.condiments,
      1700,
      1350,
      9,
    ),
    p(
      '4800237100001',
      'Magic Sarap 8g',
      ProductCategory.condiments,
      500,
      380,
      50,
      threshold: 10,
    ),
    p(
      '4800411022013',
      'Piattos Cheese 40g',
      ProductCategory.snacks,
      2000,
      1650,
      15,
    ),
    p(
      '4801913134419',
      'SkyFlakes Crackers 25g',
      ProductCategory.snacks,
      800,
      620,
      2,
      threshold: 10,
    ),
    p(
      '4800039130022',
      'Gardenia Classic White Bread',
      ProductCategory.bread,
      7500,
      6600,
      6,
      threshold: 3,
      expiry: inDays(4),
    ),
    p(
      '4800602033170',
      'Eden Cheese 165g',
      ProductCategory.dairy,
      6200,
      5300,
      5,
      threshold: 3,
      expiry: inDays(40),
    ),
    p(
      '4800176100018',
      'Safeguard Pure White Soap 60g',
      ProductCategory.personalCare,
      2900,
      2400,
      14,
    ),
    p(
      '4800281100019',
      'Palmolive Shampoo Sachet 12ml',
      ProductCategory.personalCare,
      700,
      550,
      40,
      threshold: 12,
    ),
    p(
      '4800542200229',
      'Surf Powder Detergent 65g',
      ProductCategory.household,
      1000,
      800,
      30,
      threshold: 8,
    ),
    p(
      '4800705000130',
      'Fresh Eggs (per piece)',
      ProductCategory.others,
      900,
      750,
      30,
      threshold: 12,
      expiry: inDays(10),
    ),
  ];
}

/// Inserts the sample products, skipping barcodes that already exist.
/// Returns how many were added.
Future<int> seedSampleProducts(
  ProductRepository repo, {
  required AppUser by,
  required String initialStockNote,
}) async {
  var added = 0;
  for (final product in sampleProducts()) {
    try {
      await repo.createProduct(
        product,
        by: by,
        initialStockNote: initialStockNote,
      );
      added++;
    } on DuplicateBarcodeFailure {
      // Already seeded.
    }
  }
  return added;
}
