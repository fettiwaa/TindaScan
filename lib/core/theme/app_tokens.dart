import 'package:flutter/material.dart';

/// Spacing on a 4/8 grid (logical pixels).
abstract final class Gaps {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radius tokens.
abstract final class AppRadii {
  static const double small = 12;
  static const double medium = 16;
  static const double large = 24;
  static const double pill = 999;
}

/// Size tokens. Tap targets are at least 48x48dp.
abstract final class AppSizes {
  static const double minTapTarget = 48;
  static const double primaryButtonHeight = 56;
  static const double maxContentWidth = 560;
  static const double iconLarge = 32;
  static const double avatar = 44;
  static const double radius = AppRadii.small;
  static const double outline = 1;
  static const double listPaneWidth = 380;
}

/// Layout breakpoints (Material 3 window size classes).
abstract final class Breakpoints {
  /// Below this: phone (compact).
  static const double medium = 600;

  /// At or above this: wide/web (expanded).
  static const double expanded = 1024;

  static WindowSize of(double width) => width >= expanded
      ? WindowSize.expanded
      : width >= medium
      ? WindowSize.medium
      : WindowSize.compact;
}

/// Material 3 window size classes.
enum WindowSize { compact, medium, expanded }

/// Motion tokens. Read durations through `context.motion` so they collapse
/// to zero when the user turned animations off (accessibility).
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// Delay between items of a staggered list entrance.
  static const Duration stagger = Duration(milliseconds: 40);

  /// Only the first items of a list animate in (protects performance).
  static const int maxStaggeredItems = 10;

  static const Curve enter = Curves.easeOutCubic;
  static const Curve transition = Curves.easeInOutCubic;

  /// Scale applied while a card or button is pressed.
  static const double pressedScale = 0.97;
}

/// Brand palette. The seed generates the Material 3 scheme; status colors
/// live in [AppTokens] and are used sparingly.
abstract final class AppPalette {
  /// Fresh green-teal ("tinda" = growth and freshness).
  static const Color seed = Color(0xFF0F8F6B);
  static const Color lightBackground = Color(0xFFFAFAF7);
  static const Color lightText = Color(0xFF1B1F1D);
  static const Color darkBackground = Color(0xFF111412);
  static const Color darkText = Color(0xFFE5E9E6);
}

/// Theme-aware design tokens the Material scheme lacks (status colors,
/// card outline, receipt paper, radii), exposed as a [ThemeExtension] so
/// widgets never hardcode them: `context.tokens.warning`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.cardOutline,
    required this.paper,
    required this.onPaper,
  });

  /// Light theme tokens. All text/background pairs meet WCAG AA (tested).
  static const AppTokens light = AppTokens(
    success: Color(0xFF1E7A3C),
    onSuccess: Colors.white,
    successContainer: Color(0xFFD9F2E0),
    onSuccessContainer: Color(0xFF0B3D1C),
    warning: Color(0xFF8A5300),
    onWarning: Colors.white,
    warningContainer: Color(0xFFFFEBC7),
    onWarningContainer: Color(0xFF4A2C00),
    danger: Color(0xFFB3261E),
    dangerContainer: Color(0xFFFADCD8),
    onDangerContainer: Color(0xFF5C0E09),
    cardOutline: Color(0xFFE3E5DF),
    paper: Colors.white,
    onPaper: AppPalette.lightText,
  );

  /// Dark theme tokens.
  static const AppTokens dark = AppTokens(
    success: Color(0xFF7BD88F),
    onSuccess: Color(0xFF00391A),
    successContainer: Color(0xFF15402A),
    onSuccessContainer: Color(0xFFBDF2C9),
    warning: Color(0xFFFFC266),
    onWarning: Color(0xFF452B00),
    warningContainer: Color(0xFF4A3510),
    onWarningContainer: Color(0xFFFFDDA6),
    danger: Color(0xFFFFB4AB),
    dangerContainer: Color(0xFF5C1A15),
    onDangerContainer: Color(0xFFFFDAD5),
    cardOutline: Color(0xFF2B302D),
    paper: Color(0xFF1B1F1D),
    onPaper: AppPalette.darkText,
  );

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;

  /// Thin 1px outline used instead of heavy shadows.
  final Color cardOutline;

  /// Receipt paper.
  final Color paper;
  final Color onPaper;

  @override
  AppTokens copyWith({Color? success, Color? warning, Color? danger}) =>
      AppTokens(
        success: success ?? this.success,
        onSuccess: onSuccess,
        successContainer: successContainer,
        onSuccessContainer: onSuccessContainer,
        warning: warning ?? this.warning,
        onWarning: onWarning,
        warningContainer: warningContainer,
        onWarningContainer: onWarningContainer,
        danger: danger ?? this.danger,
        dangerContainer: dangerContainer,
        onDangerContainer: onDangerContainer,
        cardOutline: cardOutline,
        paper: paper,
        onPaper: onPaper,
      );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      success: c(success, other.success),
      onSuccess: c(onSuccess, other.onSuccess),
      successContainer: c(successContainer, other.successContainer),
      onSuccessContainer: c(onSuccessContainer, other.onSuccessContainer),
      warning: c(warning, other.warning),
      onWarning: c(onWarning, other.onWarning),
      warningContainer: c(warningContainer, other.warningContainer),
      onWarningContainer: c(onWarningContainer, other.onWarningContainer),
      danger: c(danger, other.danger),
      dangerContainer: c(dangerContainer, other.dangerContainer),
      onDangerContainer: c(onDangerContainer, other.onDangerContainer),
      cardOutline: c(cardOutline, other.cardOutline),
      paper: c(paper, other.paper),
      onPaper: c(onPaper, other.onPaper),
    );
  }
}

/// Motion durations for the current context; all zero when the platform
/// asks to disable animations (`MediaQuery.disableAnimations`).
@immutable
class MotionTokens {
  const MotionTokens({required this.enabled});

  final bool enabled;

  Duration get fast => enabled ? AppMotion.fast : Duration.zero;
  Duration get normal => enabled ? AppMotion.normal : Duration.zero;
  Duration get slow => enabled ? AppMotion.slow : Duration.zero;
  Duration get stagger => enabled ? AppMotion.stagger : Duration.zero;
}

/// Short accessors: `context.tokens`, `context.motion`, `context.windowSize`.
extension ThemeTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;

  MotionTokens get motion =>
      MotionTokens(enabled: !MediaQuery.disableAnimationsOf(this));

  WindowSize get windowSize => Breakpoints.of(MediaQuery.sizeOf(this).width);
}
