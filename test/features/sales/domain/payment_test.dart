import 'package:flutter_test/flutter_test.dart';
import 'package:tindascan/features/sales/domain/cart.dart';
import 'package:tindascan/features/sales/domain/checkout_request.dart';
import 'package:tindascan/features/sales/domain/payment.dart';
import 'package:tindascan/features/sales/domain/receipt_number.dart';

import '../../../helpers/fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('Payment.change', () {
    test('computes change exactly in centavos', () {
      expect(Payment.change(totalCentavos: 3750, tenderedCentavos: 5000), 1250);
      expect(Payment.change(totalCentavos: 3750, tenderedCentavos: 3750), 0);
    });

    test('returns null when tendered is short', () {
      expect(
        Payment.change(totalCentavos: 3750, tenderedCentavos: 3749),
        isNull,
      );
      expect(
        Payment.isSufficient(totalCentavos: 100, tenderedCentavos: 99),
        isFalse,
      );
    });
  });

  group('Payment.quickAmounts', () {
    test('suggests exact then round bills', () {
      expect(Payment.quickAmounts(3700), [
        3700,
        5000,
        10000,
        20000,
        50000,
        100000,
      ]);
    });

    test('skips bills that do not cover the total; rounds large totals', () {
      expect(Payment.quickAmounts(10000), [10000, 20000, 50000, 100000]);
      expect(Payment.quickAmounts(123456), [123456, 200000]);
    });

    test('empty for a zero total', () {
      expect(Payment.quickAmounts(0), isEmpty);
    });
  });

  group('ReceiptNumber', () {
    test('online numbers are zero-padded per day', () {
      expect(ReceiptNumber.online('20261119', 7), '20261119-0007');
      expect(ReceiptNumber.online('20261119', 12345), '20261119-12345');
    });

    test('offline numbers use a sale id fragment', () {
      expect(
        ReceiptNumber.offline('20261119', 'abc123xyz'),
        '20261119-XABC123',
      );
    });
  });

  group('CheckoutRequest.buildSale', () {
    test('builds items, totals and change from fresh product data', () {
      final p = product(stock: 5);
      final request = CheckoutRequest(
        saleId: 's1',
        cart: const Cart().add(p, qty: 2),
        tenderedCentavos: 5000,
        cashier: testStaff,
        now: DateTime.utc(2026, 11, 19),
      );
      final sale = request.buildSale(
        receiptNo: 'R',
        dayKey: '20261119',
        offline: false,
        products: {'p1': p.copyWith(costPriceCentavos: 1000)},
      );
      expect(sale.totalCentavos, 3200);
      expect(sale.costTotalCentavos, 2000);
      expect(sale.changeCentavos, 1800);
      expect(sale.profitCentavos, 1200);
      expect(sale.itemCount, 2);
      expect(sale.cashierId, testStaff.uid);
      expect(sale.items.single.subtotalCentavos, 3200);
    });
  });
}
