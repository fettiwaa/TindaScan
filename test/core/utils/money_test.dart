import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/utils/money.dart';

void main() {
  group('Money.format', () {
    test('formats centavos with peso sign and grouping', () {
      expect(Money.format(0), '₱0.00');
      expect(Money.format(5), '₱0.05');
      expect(Money.format(1600), '₱16.00');
      expect(Money.format(123456789), '₱1,234,567.89');
    });

    test('formats negatives with a leading minus', () {
      expect(Money.format(-250), '-₱2.50');
    });

    test('can omit the symbol', () {
      expect(Money.format(1050, withSymbol: false), '10.50');
      expect(Money.toInput(123450), '1234.50');
    });
  });

  group('Money.tryParse', () {
    test('parses whole and fractional pesos exactly', () {
      expect(Money.tryParse('12'), 1200);
      expect(Money.tryParse('12.5'), 1250);
      expect(Money.tryParse('12.05'), 1205);
      expect(Money.tryParse('0.1'), 10);
      expect(Money.tryParse('1.'), 100);
    });

    test('accepts grouping, peso sign and whitespace', () {
      expect(Money.tryParse(' ₱1,234.50 '), 123450);
    });

    test('avoids floating point drift', () {
      // 0.1 + 0.2 style inputs must be exact in centavos.
      expect(Money.tryParse('0.29'), 29);
      expect(Money.tryParse('19.99'), 1999);
    });

    test('rejects invalid, negative and over-precise input', () {
      expect(Money.tryParse(''), isNull);
      expect(Money.tryParse('abc'), isNull);
      expect(Money.tryParse('-5'), isNull);
      expect(Money.tryParse('1.234'), isNull);
      expect(Money.tryParse('1.2.3'), isNull);
      expect(Money.tryParse('99999999'), isNull);
    });
  });
}
