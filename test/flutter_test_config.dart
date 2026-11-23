import 'dart:async';

import 'package:tindascan/core/theme/app_typography.dart';

/// Global test setup: no network fonts in tests (Google Fonts would try to
/// download Plus Jakarta Sans), so the default test font is used.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppTypography.useGoogleFonts = false;
  await testMain();
}
