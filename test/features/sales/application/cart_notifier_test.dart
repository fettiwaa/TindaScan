import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/features/sales/application/cart_notifier.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';
import 'package:tindascan/shared/repositories/product_repository.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository products;

  setUp(() => products = MockProductRepository());

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(products)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('CartNotifier.addByBarcode', () {
    test('adds a new line, then +1 per scan of the same code', () async {
      when(
        () => products.findByBarcode('4800016644283'),
      ).thenAnswer((_) async => product(stock: 5));
      final cart = container().read(cartProvider.notifier);

      await cart.addByBarcode('4800016644283');
      final result = await cart.addByBarcode(' 4800 0166 44283 ');

      expect(result.lines.single.qty, 2);
      expect(result.totalCentavos, 3200);
    });

    test('unknown or archived products throw ProductNotFound', () async {
      when(
        () => products.findByBarcode('111111'),
      ).thenAnswer((_) async => null);
      when(
        () => products.findByBarcode('222222'),
      ).thenAnswer((_) async => product(active: false));
      final cart = container().read(cartProvider.notifier);

      await expectLater(
        cart.addByBarcode('111111'),
        throwsA(
          isA<ProductNotFound>().having((f) => f.barcode, 'barcode', '111111'),
        ),
      );
      await expectLater(
        cart.addByBarcode('222222'),
        throwsA(isA<ProductNotFound>()),
      );
    });

    test('malformed codes fail without a lookup', () async {
      final cart = container().read(cartProvider.notifier);
      await expectLater(
        cart.addByBarcode('48/00'),
        throwsA(isA<ProductNotFound>()),
      );
      verifyNever(() => products.findByBarcode(any()));
    });

    test('blocks quantities above stock; cart unchanged', () async {
      when(
        () => products.findByBarcode('4800016644283'),
      ).thenAnswer((_) async => product(stock: 1));
      final c = container();
      final cart = c.read(cartProvider.notifier);
      await cart.addByBarcode('4800016644283');

      await expectLater(
        cart.addByBarcode('4800016644283'),
        throwsA(isA<InsufficientStock>()),
      );
      expect(c.read(cartProvider).lines.single.qty, 1);
    });

    test('maps repository errors to typed failures', () async {
      when(
        () => products.findByBarcode(any()),
      ).thenThrow(const NetworkUnavailable());
      await expectLater(
        container().read(cartProvider.notifier).addByBarcode('4800016644283'),
        throwsA(isA<NetworkUnavailable>()),
      );
    });
  });

  group('cartSessionGuardProvider', () {
    test('clears the cart when the signed-in account changes', () async {
      final uids = StreamController<String?>();
      addTearDown(uids.close);
      final auth = MockAuthRepository();
      when(auth.uidChanges).thenAnswer((_) => uids.stream);
      final c = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(products),
          authRepositoryProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(c.dispose);
      c.listen(cartSessionGuardProvider, (_, _) {});

      uids.add('cashier-a');
      await pumpEventQueue();
      c.read(cartProvider.notifier).add(product(stock: 5));
      expect(c.read(cartProvider).isEmpty, isFalse);

      uids.add('cashier-a'); // Same account: the cart is kept.
      await pumpEventQueue();
      expect(c.read(cartProvider).isEmpty, isFalse);

      uids.add('cashier-b');
      await pumpEventQueue();
      expect(c.read(cartProvider).isEmpty, isTrue);
    });
  });
}
