import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/features/auth/domain/auth_validators.dart';
import 'package:tindascan/shared/models/user_role.dart';

/// Maps validator results to localized text (null = valid).
extension AuthFieldErrorText on AuthFieldError? {
  String? toText(
    AppLocalizations l10n, {
    int maxLength = AppConstants.maxNameLength,
  }) => switch (this) {
    null => null,
    AuthFieldError.required => l10n.fieldRequired,
    AuthFieldError.invalidEmail => l10n.fieldInvalidEmail,
    AuthFieldError.passwordTooShort => l10n.fieldPasswordTooShort(
      AppConstants.minPasswordLength,
    ),
    AuthFieldError.passwordMismatch => l10n.fieldPasswordMismatch,
    AuthFieldError.tooLong => l10n.fieldTooLong(maxLength),
  };
}

/// Localized role label.
extension UserRoleLabel on UserRole {
  String label(AppLocalizations l10n) => switch (this) {
    UserRole.owner => l10n.roleOwner,
    UserRole.staff => l10n.roleStaff,
  };
}
