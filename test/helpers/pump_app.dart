import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod's Override type lives in misc.dart in v3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_theme.dart';

/// Pumps [child] inside a localized MaterialApp and a ProviderScope.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget child, {
    List<Override> overrides = const [],
    Locale locale = const Locale('en'),
    double textScale = 1,
    bool dark = false,
    bool disableAnimations = false,
  }) => pumpWidget(
    ProviderScope(
      overrides: overrides,
      retry: (_, _) => null,
      child: MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: child,
      ),
    ),
  );
}
