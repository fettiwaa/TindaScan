import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Minimal logger that scrubs personal data before anything is written.
///
/// Rule: never pass passwords to the logger. As a second line of defence,
/// e-mail addresses and long digit runs (phone numbers) are masked.
abstract final class AppLogger {
  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
  static final RegExp _longDigits = RegExp(r'\b\d{10,}\b');

  /// Masks e-mails and phone-like numbers in [message].
  static String redact(String message) =>
      message.replaceAll(_email, '<email>').replaceAll(_longDigits, '<number>');

  /// Logs an informational message (debug builds only).
  static void info(String message) {
    if (kDebugMode) {
      developer.log(redact(message), name: 'TindaScan');
    }
  }

  /// Logs an error with its stack trace. Only the error *type* and a redacted
  /// message are recorded — never the raw object, which may hold user input.
  static void error(String context, Object error, [StackTrace? stack]) {
    final message = redact('$context: ${error.runtimeType}: $error');
    developer.log(message, name: 'TindaScan', level: 1000, stackTrace: stack);
  }
}
