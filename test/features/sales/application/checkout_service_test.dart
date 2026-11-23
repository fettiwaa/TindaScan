import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tindascan/core/connectivity/connectivity_providers.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/core/services/local_prefs.dart';
import 'package:tindascan/features/alerts/data/notification_service.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/sales/application/cart_notifier.dart';
import 'package:tindascan/features/sales/application/checkout_service.dart';
import 'package:tindascan/features/sales/domain/cart.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/sale.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';
import 'package:tindascan/shared/repositories/product_repository.dart';
import 'package:tindascan/shared/repositories/sales_repository.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';
import '../../../helpers/test_app.dart';

class MockSalesRepository extends Mock implements SalesRepository {}

class MockProductRepository extends Mock implements ProductRepository {}

Sale saleOf(Cart cart, int tendered, {bool offline = false}) => Sale(
  id: 'sale-1',
  receiptNo: offline ? '20261121-XSALE-1' : '20261121-0001',
  items: const [],
  totalCentavos: cart.totalCentavos,
  costTotalCentavos: cart.costTotalCentavos,
  amountTenderedCentavos: tendered,
  changeCentavos: tendered - cart.totalCentavos,
  cashierId: 'staff-1',
  cashierName: 'Juan',
  dayKey: '20261121',
  offline: offline,
);

void main() {
  late MockSalesRepository sales;
  late MockProductRepository products;
  late FakeAlertNotifier notifier;

  setUpAll(() {
    registerFallbackValue(const Cart());
    registerFallbackValue(testStaff);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    sales = MockSalesRepository();
    products = MockProductRepository();
    notifier = FakeAlertNotifier();
    when(sales.newSaleId).thenReturn('sale-1');
  });

  void stubOnline(Future<Sale> Function(Cart cart, int tendered) answer) {
    when(
      () => sales.createSale(
        any(),
        any(),
        cashier: any(named: 'cashier'),
        saleId: any(named: 'saleId'),
        now: any(named: 'now'),
      ),
    ).thenAnswer(
      (i) => answer(
        i.positionalArguments[0] as Cart,
        i.positionalArguments[1] as int,
      ),
    );
  }

  void stubOffline() {
    when(
      () => sales.createSaleOffline(
        any(),
        any(),
        cashier: any(named: 'cashier'),
        saleId: any(named: 'saleId'),
        now: any(named: 'now'),
      ),
    ).thenAnswer(
      (i) async => saleOf(
        i.positionalArguments[0] as Cart,
        i.positionalArguments[1] as int,
        offline: true,
      ),
    );
  }

  ProviderContainer container({bool online = true, AppUser? user = testStaff}) {
    final c = ProviderContainer(
      overrides: [
        salesRepositoryProvider.overrideWithValue(sales),
        productRepositoryProvider.overrideWithValue(products),
        currentUserProvider.overrideWithValue(user),
        isOnlineProvider.overrideWithValue(AsyncData(online)),
        alertNotifierProvider.overrideWithValue(notifier),
        localPrefsProvider.overrideWithValue(MemoryLocalPrefs()),
      ],
      retry: (_, _) => null,
    );
    addTearDown(c.dispose);
    return c;
  }

  Cart fill(ProviderContainer c, {int qty = 1, int stock = 5}) {
    c.read(cartProvider.notifier).add(product(stock: stock), qty: qty);
    return c.read(cartProvider);
  }

  test('online sale uses createSale and clears the cart', () async {
    stubOnline((cart, tendered) async => saleOf(cart, tendered));
    final c = container();
    final cart = fill(c);

    final sale = await c.read(checkoutServiceProvider).checkout(cart, 2000);

    expect(sale.changeCentavos, 400);
    expect(c.read(cartProvider).isEmpty, isTrue);
    verify(
      () => sales.createSale(
        cart,
        2000,
        cashier: testStaff,
        saleId: 'sale-1',
        now: any(named: 'now'),
      ),
    ).called(1);
    verifyNever(
      () => sales.createSaleOffline(
        any(),
        any(),
        cashier: any(named: 'cashier'),
        saleId: any(named: 'saleId'),
        now: any(named: 'now'),
      ),
    );
  });

  test('offline sale uses the batched fallback', () async {
    stubOffline();
    final c = container(online: false);
    final sale = await c.read(checkoutServiceProvider).checkout(fill(c), 2000);
    expect(sale.offline, isTrue);
  });

  test('falls back to offline when the transaction has no network', () async {
    stubOnline((_, _) => throw const NetworkUnavailable());
    stubOffline();
    final c = container();
    final sale = await c.read(checkoutServiceProvider).checkout(fill(c), 2000);
    expect(sale.offline, isTrue);
  });

  test('InvalidPayment for short cash or an empty cart, without I/O', () async {
    final c = container();
    final service = c.read(checkoutServiceProvider);
    await expectLater(
      service.checkout(fill(c), 100),
      throwsA(isA<InvalidPayment>()),
    );
    await expectLater(
      service.checkout(const Cart(), 100),
      throwsA(isA<InvalidPayment>()),
    );
    verifyNever(sales.newSaleId);
  });

  test('PermissionDenied without an active cashier', () async {
    final c = container(user: testStaff.copyWith(active: false));
    await expectLater(
      c.read(checkoutServiceProvider).checkout(fill(c), 2000),
      throwsA(isA<PermissionDenied>()),
    );
  });

  test('stock conflict refreshes the cart and rethrows', () async {
    stubOnline(
      (_, _) => throw const InsufficientStock(productName: 'X', available: 1),
    );
    when(
      () => products.getProduct('p1'),
    ).thenAnswer((_) async => product(stock: 1));
    final c = container();
    final cart = fill(c, qty: 3);

    await expectLater(
      c.read(checkoutServiceProvider).checkout(cart, 10000),
      throwsA(isA<InsufficientStock>()),
    );
    expect(c.read(cartProvider).lines.single.qty, 1);
  });

  test('a double tap returns the same pending sale (one write)', () async {
    final gate = Completer<void>();
    stubOnline((cart, tendered) async {
      await gate.future;
      return saleOf(cart, tendered);
    });
    final c = container();
    final cart = fill(c);
    final service = c.read(checkoutServiceProvider);

    final first = service.checkout(cart, 2000);
    final second = service.checkout(cart, 2000);
    gate.complete();

    expect(identical(await first, await second), isTrue);
    verify(
      () => sales.createSale(
        any(),
        any(),
        cashier: any(named: 'cashier'),
        saleId: any(named: 'saleId'),
        now: any(named: 'now'),
      ),
    ).called(1);
  });

  test('a retry of the same cart reuses the sale id', () async {
    var calls = 0;
    stubOnline((cart, tendered) async {
      if (calls++ == 0) throw const ConflictFailure();
      return saleOf(cart, tendered);
    });
    final c = container();
    final cart = fill(c);
    final service = c.read(checkoutServiceProvider);

    await expectLater(service.checkout(cart, 2000), throwsA(anything));
    await service.checkout(cart, 2000);

    verify(
      () => sales.createSale(
        any(),
        any(),
        cashier: any(named: 'cashier'),
        saleId: 'sale-1',
        now: any(named: 'now'),
      ),
    ).called(2);
    verify(sales.newSaleId).called(1);
  });

  test('hands the new stock levels to AlertService', () async {
    stubOnline((cart, tendered) async => saleOf(cart, tendered));
    final c = container(user: testOwner);
    // 4 in stock, threshold 3: selling 2 leaves 2, which is low.
    final cart = fill(c, qty: 2, stock: 4);

    await c.read(checkoutServiceProvider).checkout(cart, 10000);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.shown.single.single.stockQty, 2);
  });
}
