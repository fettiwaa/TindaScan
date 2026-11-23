import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/theme/app_theme.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/animated_counter.dart';
import 'package:tindascan/core/widgets/motion.dart';
import 'package:tindascan/core/widgets/stock_pill.dart';
import 'package:tindascan/features/settings/presentation/design_gallery_screen.dart';

import '../helpers/pump_app.dart';

/// WCAG relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// WCAG contrast ratio between two opaque colors.
double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('WCAG AA contrast', () {
    for (final (name, theme) in [
      ('light', AppTheme.light()),
      ('dark', AppTheme.dark()),
    ]) {
      final s = theme.colorScheme;
      final t = theme.extension<AppTokens>()!;
      final normalText = <String, (Color, Color)>{
        'onSurface/surface': (s.onSurface, s.surface),
        'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
        'onSurface/card': (s.onSurface, s.surfaceContainerLowest),
        'onPrimary/primary': (s.onPrimary, s.primary),
        'onPrimaryContainer/primaryContainer': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        'success text/card': (t.success, s.surfaceContainerLowest),
        'warning text/card': (t.warning, s.surfaceContainerLowest),
        'danger text/card': (t.danger, s.surfaceContainerLowest),
        'success pill': (t.onSuccessContainer, t.successContainer),
        'warning pill': (t.onWarningContainer, t.warningContainer),
        'danger pill': (t.onDangerContainer, t.dangerContainer),
        'receipt': (t.onPaper, t.paper),
      };
      for (final entry in normalText.entries) {
        test('$name: ${entry.key} >= 4.5', () {
          final (fg, bg) = entry.value;
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }
      test('$name: primary on primaryContainer (large text) >= 3', () {
        expect(
          contrast(s.primary, s.primaryContainer),
          greaterThanOrEqualTo(3),
        );
      });
    }
  });

  group('Reduced motion', () {
    testWidgets('AnimatedCounter jumps to the new value immediately', (
      tester,
    ) async {
      Widget counter(int v) => AnimatedCounter(value: v);
      await tester.pumpApp(counter(10), disableAnimations: true);
      await tester.pumpApp(counter(99), disableAnimations: true);
      await tester.pump();
      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('AnimatedCounter counts up when motion is allowed', (
      tester,
    ) async {
      await tester.pumpApp(const AnimatedCounter(value: 0));
      await tester.pumpApp(const AnimatedCounter(value: 100));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('100'), findsNothing, reason: 'still animating');
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('staggered entrances are skipped when disabled', (
      tester,
    ) async {
      await tester.pumpApp(
        Builder(builder: (c) => const Text('row').staggerIn(c, 0)),
        disableAnimations: true,
      );
      expect(find.byType(Animate), findsNothing);
      expect(find.text('row'), findsOneWidget);
    });

    testWidgets('staggered entrances animate only the first items', (
      tester,
    ) async {
      await tester.pumpApp(
        Builder(
          builder: (c) => Column(
            children: [
              const Text('first').staggerIn(c, 0),
              const Text('late').staggerIn(c, AppMotion.maxStaggeredItems),
            ],
          ),
        ),
      );
      expect(find.byType(Animate), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('motion tokens collapse to zero', (tester) async {
      late MotionTokens motion;
      await tester.pumpApp(
        Builder(
          builder: (c) {
            motion = c.motion;
            return const SizedBox();
          },
        ),
        disableAnimations: true,
      );
      expect(motion.enabled, isFalse);
      expect(motion.slow, Duration.zero);
    });
  });

  test('stock levels', () {
    expect(StockLevel.of(stock: 10, threshold: 5), StockLevel.ok);
    expect(StockLevel.of(stock: 5, threshold: 5), StockLevel.low);
    expect(StockLevel.of(stock: 0, threshold: 5), StockLevel.out);
    expect(StockLevel.of(stock: -2, threshold: 5), StockLevel.out);
  });

  test('breakpoints', () {
    expect(Breakpoints.of(390), WindowSize.compact);
    expect(Breakpoints.of(800), WindowSize.medium);
    expect(Breakpoints.of(1280), WindowSize.expanded);
  });

  for (final dark in [false, true]) {
    testWidgets('design gallery renders (${dark ? 'dark' : 'light'})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpApp(
        const Scaffold(body: DesignGalleryBody()),
        dark: dark,
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      // Rows built by the scroll start their entrance on the next frame.
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
