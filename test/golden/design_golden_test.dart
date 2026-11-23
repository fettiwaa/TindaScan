// Golden (pixel) tests for key components and the Sell screen, in light
// and dark themes. Regenerate after intentional design changes:
//   flutter test --update-goldens --tags golden
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/services/local_prefs.dart';
import 'package:tindascan/core/utils/money.dart';
import 'package:tindascan/core/widgets/stat_card.dart';
import 'package:tindascan/core/widgets/stock_pill.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/sales/application/cart_notifier.dart';
import 'package:tindascan/features/sales/domain/cart.dart';
import 'package:tindascan/features/sales/presentation/sell_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/mocks.dart';
import '../helpers/pump_app.dart';

class _PrefilledCart extends CartNotifier {
  @override
  Cart build() => const Cart()
      .add(product(), qty: 2)
      .add(
        product(
          id: 'p2',
          barcode: '4800194104104',
          name: 'Bear Brand Powdered Milk 33g',
          price: 1300,
        ),
      );
}

void main() {
  void phone(WidgetTester tester, {double height = 900}) {
    tester.view.physicalSize = Size(400, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';

    testWidgets('StatCard ($theme)', (tester) async {
      phone(tester, height: 300);
      await tester.pumpApp(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: "Today's sales",
                    value: 123450,
                    format: Money.format,
                    emphasis: true,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Transactions',
                    icon: Icons.receipt_long,
                    value: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        dark: dark,
        disableAnimations: true,
      );
      await tester.pump();
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/stat_card_$theme.png'),
      );
    });

    testWidgets('StockPill ($theme)', (tester) async {
      phone(tester, height: 120);
      await tester.pumpApp(
        const Scaffold(
          body: Center(
            child: Wrap(
              spacing: 8,
              children: [
                StockPill(stock: 24, threshold: 5),
                StockPill(stock: 3, threshold: 5),
                StockPill(stock: 0, threshold: 5),
              ],
            ),
          ),
        ),
        dark: dark,
        disableAnimations: true,
      );
      await tester.pump();
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/stock_pill_$theme.png'),
      );
    });

    testWidgets('Sell screen with a cart ($theme)', (tester) async {
      phone(tester);
      await tester.pumpApp(
        const SellScreen(),
        dark: dark,
        disableAnimations: true,
        overrides: [
          cartProvider.overrideWith(_PrefilledCart.new),
          currentUserProvider.overrideWithValue(testStaff),
          localPrefsProvider.overrideWithValue(MemoryLocalPrefs()),
        ],
      );
      await tester.pump();
      await expectLater(
        find.byType(SellScreen),
        matchesGoldenFile('goldens/sell_screen_$theme.png'),
      );
    });
  }
}
