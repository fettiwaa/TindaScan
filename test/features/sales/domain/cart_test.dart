import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/features/sales/domain/cart.dart';

import '../../../helpers/fixtures.dart';

void main() {
  final canton = product(stock: 3);
  final milk = product(
    id: 'p2',
    barcode: '4800194104104',
    name: 'Bear Brand',
    price: 1300,
    cost: 1050,
  );

  group('Cart', () {
    test('adds and merges lines, computing exact totals', () {
      final cart = const Cart().add(canton).add(canton).add(milk);
      expect(cart.lines, hasLength(2));
      expect(cart.quantityOf('p1'), 2);
      expect(cart.itemCount, 3);
      expect(cart.totalCentavos, 1600 * 2 + 1300);
      expect(cart.costTotalCentavos, 1250 * 2 + 1050);
    });

    test('blocks quantities above available stock', () {
      final cart = const Cart().add(canton, qty: 3);
      expect(
        () => cart.add(canton),
        throwsA(
          isA<InsufficientStock>()
              .having((f) => f.available, 'available', 3)
              .having((f) => f.productName, 'name', canton.name),
        ),
      );
    });

    test('rejects out-of-stock and archived products', () {
      expect(
        () => const Cart().add(product(stock: 0)),
        throwsA(isA<InsufficientStock>()),
      );
      expect(
        () => const Cart().add(product(active: false)),
        throwsA(isA<ProductNotFound>()),
      );
    });

    test('setQuantity to zero removes the line', () {
      final cart = const Cart().add(canton).setQuantity(canton, 0);
      expect(cart.isEmpty, isTrue);
    });

    test('remove and equality', () {
      final cart = const Cart().add(canton).add(milk).remove('p1');
      expect(cart.lines.single.product.id, 'p2');
      expect(const Cart().add(milk), cart);
    });

    test('refresh updates prices, clamps quantities and drops gone items', () {
      final cart = const Cart().add(canton, qty: 3).add(milk);
      final refreshed = cart.refresh({
        'p1': canton.copyWith(stockQty: 1, unitPriceCentavos: 1700),
        'p2': null,
      });
      expect(refreshed.lines.single.qty, 1);
      expect(refreshed.totalCentavos, 1700);
    });
  });
}
