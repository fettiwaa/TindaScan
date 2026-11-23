import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/router/transitions.dart';

/// The rendered opacity of the branch that contains [text].
double _opacityOf(WidgetTester tester, String text) => tester
    .renderObject<RenderAnimatedOpacity>(
      find.ancestor(
        of: find.text(text),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity
    .value;

void main() {
  Future<void> pumpAt(WidgetTester tester, int index) => tester.pumpWidget(
    MaterialApp(
      home: FadeBranchContainer(
        currentIndex: index,
        children: const [Text('Sell'), Text('More')],
      ),
    ),
  );

  testWidgets('the branch on top fades out when leaving it', (tester) async {
    // "More" is last, so it is painted on top of "Sell".
    await pumpAt(tester, 1);
    await tester.pumpAndSettle();
    expect(_opacityOf(tester, 'More'), 1);

    await pumpAt(tester, 0);
    await tester.pumpAndSettle();

    // Regression: muting the leaving branch's ticker froze this at 1, so
    // More stayed visible over Sell.
    expect(_opacityOf(tester, 'More'), 0);
    expect(_opacityOf(tester, 'Sell'), 1);
  });
}
