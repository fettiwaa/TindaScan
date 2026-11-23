import 'package:flutter/foundation.dart';

import 'package:tindascan/core/errors/app_logger.dart';

/// Installs handlers for uncaught framework and platform errors.
///
/// Errors are logged through [AppLogger] (which redacts personal data). In a
/// production deployment this is where Crashlytics would be wired in.
void installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    AppLogger.error('FlutterError', details.exception, details.stack);
    if (kDebugMode) FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Uncaught', error, stack);
    return true;
  };
}
