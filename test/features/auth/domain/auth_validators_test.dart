import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/features/auth/domain/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('email', () {
      expect(AuthValidators.email(null), AuthFieldError.required);
      expect(AuthValidators.email('  '), AuthFieldError.required);
      expect(AuthValidators.email('nena'), AuthFieldError.invalidEmail);
      expect(AuthValidators.email('nena@store'), AuthFieldError.invalidEmail);
      expect(AuthValidators.email(' nena@store.ph '), isNull);
      expect(AuthValidators.email('${'a' * 120}@x.ph'), AuthFieldError.tooLong);
    });

    test('new password enforces minimum length', () {
      expect(AuthValidators.newPassword(''), AuthFieldError.required);
      expect(
        AuthValidators.newPassword('a' * (AppConstants.minPasswordLength - 1)),
        AuthFieldError.passwordTooShort,
      );
      expect(
        AuthValidators.newPassword('a' * AppConstants.minPasswordLength),
        isNull,
      );
    });

    test('login password only requires a value', () {
      expect(AuthValidators.loginPassword(''), AuthFieldError.required);
      expect(AuthValidators.loginPassword('x'), isNull);
    });

    test('confirm password must match', () {
      expect(
        AuthValidators.confirmPassword('abc', 'abd'),
        AuthFieldError.passwordMismatch,
      );
      expect(AuthValidators.confirmPassword('abc', 'abc'), isNull);
    });

    test('name is required and length-limited', () {
      expect(AuthValidators.name(' '), AuthFieldError.required);
      expect(AuthValidators.name('Juan'), isNull);
      expect(
        AuthValidators.name('a' * (AppConstants.maxNameLength + 1)),
        AuthFieldError.tooLong,
      );
      expect(
        AuthValidators.name('abcdef', maxLength: 5),
        AuthFieldError.tooLong,
      );
    });
  });
}
