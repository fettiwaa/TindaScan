import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Type scale: display (totals), title, body, label. Two weights only
/// (regular 400 and semibold 600).
abstract final class AppTypography {
  /// Google Fonts are fetched once and cached by the plugin; offline on the
  /// very first launch the platform font is used. Set to false in tests
  /// (no network there) via `test/flutter_test_config.dart`.
  static bool useGoogleFonts = true;

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semibold = FontWeight.w600;

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Plus Jakarta Sans text theme with the app's weights.
  static TextTheme textTheme(TextTheme base, ColorScheme scheme) {
    final themed = useGoogleFonts
        ? GoogleFonts.plusJakartaSansTextTheme(base)
        : base;
    TextStyle? w(TextStyle? s, FontWeight weight) =>
        s?.copyWith(fontWeight: weight, color: scheme.onSurface);
    return themed.copyWith(
      displayLarge: w(themed.displayLarge, semibold),
      displayMedium: w(themed.displayMedium, semibold),
      displaySmall: w(themed.displaySmall, semibold),
      headlineLarge: w(themed.headlineLarge, semibold),
      headlineMedium: w(themed.headlineMedium, semibold),
      headlineSmall: w(themed.headlineSmall, semibold),
      titleLarge: w(themed.titleLarge, semibold),
      titleMedium: w(themed.titleMedium, semibold),
      titleSmall: w(themed.titleSmall, semibold),
      bodyLarge: w(themed.bodyLarge, regular),
      bodyMedium: w(themed.bodyMedium, regular),
      bodySmall: w(
        themed.bodySmall,
        regular,
      )?.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: w(themed.labelLarge, semibold),
      labelMedium: w(themed.labelMedium, semibold),
      labelSmall: w(themed.labelSmall, semibold),
    );
  }

  /// Adds tabular (fixed-width) figures so prices and quantities do not
  /// jitter while they animate or change.
  static TextStyle? tabular(TextStyle? style) =>
      style?.copyWith(fontFeatures: _tabular);

  /// Monospace style for the receipt.
  static TextStyle mono(TextStyle? base) {
    final style = (base ?? const TextStyle()).copyWith(fontFeatures: _tabular);
    return useGoogleFonts
        ? GoogleFonts.jetBrainsMono(textStyle: style)
        : style.copyWith(fontFamily: 'monospace');
  }
}

/// `context.text` shortcut for the current text theme.
extension TextThemeContext on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
}
