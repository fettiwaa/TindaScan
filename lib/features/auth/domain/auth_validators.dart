import 'package:tindascan/core/constants/app_constants.dart';

/// Validation errors for auth forms, mapped to localized text in the UI.
enum AuthFieldError {
  required,
  invalidEmail,
  passwordTooShort,
  passwordMismatch,
  tooLong,
}

/// Pure validators shared by the login, setup and staff forms.
abstract final class AuthValidators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static AuthFieldError? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return AuthFieldError.required;
    if (input.length > AppConstants.maxEmailLength) {
      return AuthFieldError.tooLong;
    }
    if (!_emailPattern.hasMatch(input)) return AuthFieldError.invalidEmail;
    return null;
  }

  /// For login we only require a value; length rules apply on creation.
  static AuthFieldError? loginPassword(String? value) =>
      (value == null || value.isEmpty) ? AuthFieldError.required : null;

  static AuthFieldError? newPassword(String? value) {
    if (value == null || value.isEmpty) return AuthFieldError.required;
    if (value.length < AppConstants.minPasswordLength) {
      return AuthFieldError.passwordTooShort;
    }
    return null;
  }

  static AuthFieldError? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return AuthFieldError.required;
    return value == original ? null : AuthFieldError.passwordMismatch;
  }

  static AuthFieldError? name(
    String? value, {
    int maxLength = AppConstants.maxNameLength,
  }) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return AuthFieldError.required;
    if (input.length > maxLength) return AuthFieldError.tooLong;
    return null;
  }
}
