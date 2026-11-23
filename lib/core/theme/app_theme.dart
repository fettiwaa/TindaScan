import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/theme/app_typography.dart';

/// Material 3 light and dark themes built from one seed color.
///
/// Calm, minimal look: warm off-white background, white cards with a thin
/// outline instead of shadows, one accent color, big tap targets.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.seed,
          brightness: brightness,
        ).copyWith(
          surface: isLight
              ? AppPalette.lightBackground
              : AppPalette.darkBackground,
          onSurface: isLight ? AppPalette.lightText : AppPalette.darkText,
          surfaceContainerLowest: isLight
              ? Colors.white
              : const Color(0xFF161A18),
          surfaceContainerLow: isLight
              ? const Color(0xFFF4F5F1)
              : const Color(0xFF1A1E1C),
          error: tokens.danger,
          errorContainer: tokens.dangerContainer,
          onErrorContainer: tokens.onDangerContainer,
          outlineVariant: tokens.cardOutline,
        );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: brightness,
    );
    final text = AppTypography.textTheme(base.textTheme, scheme);

    RoundedRectangleBorder rounded(double radius, {BorderSide? side}) =>
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: side ?? BorderSide.none,
        );
    final outline = BorderSide(color: tokens.cardOutline);
    const buttonSize = Size(
      AppSizes.minTapTarget,
      AppSizes.primaryButtonHeight,
    );
    const transitions = SharedAxisPageTransitionsBuilder(
      transitionType: SharedAxisTransitionType.horizontal,
    );

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [tokens],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: transitions,
          TargetPlatform.iOS: transitions,
          TargetPlatform.linux: transitions,
          TargetPlatform.macOS: transitions,
          TargetPlatform.windows: transitions,
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: rounded(AppRadii.medium, side: outline),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.cardOutline,
        thickness: AppSizes.outline,
        space: AppSizes.outline,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: rounded(AppRadii.medium),
          textStyle: text.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: rounded(AppRadii.medium),
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          shape: rounded(AppRadii.small),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        highlightElevation: 2,
        shape: rounded(AppRadii.large),
        extendedTextStyle: text.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gaps.md,
          vertical: Gaps.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          borderSide: outline,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          borderSide: outline,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: outline,
        backgroundColor: scheme.surfaceContainerLowest,
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: Gaps.sm),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        selectedLabelTextStyle: text.labelLarge,
        unselectedLabelTextStyle: text.labelLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.large),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: rounded(AppRadii.large),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded(AppRadii.small),
        insetPadding: const EdgeInsets.fromLTRB(Gaps.md, 0, Gaps.md, Gaps.md),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: Gaps.sm,
        contentPadding: const EdgeInsets.symmetric(horizontal: Gaps.md),
        shape: rounded(AppRadii.small),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          textStyle: text.labelLarge,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 8,
      ),
    );
  }
}
