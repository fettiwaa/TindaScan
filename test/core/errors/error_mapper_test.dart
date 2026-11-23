import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/errors/app_logger.dart';
import 'package:tindascan/core/errors/error_mapper.dart';
import 'package:tindascan/core/errors/failure.dart';

void main() {
  group('mapError', () {
    test('maps auth codes to friendly failures', () {
      expect(
        mapError(FirebaseAuthException(code: 'invalid-credential')),
        isA<AuthFailure>().having(
          (f) => f.reason,
          'reason',
          AuthFailureReason.invalidCredentials,
        ),
      );
      expect(
        mapError(FirebaseAuthException(code: 'email-already-in-use')),
        isA<AuthFailure>().having(
          (f) => f.reason,
          'reason',
          AuthFailureReason.emailAlreadyInUse,
        ),
      );
      expect(
        mapError(FirebaseAuthException(code: 'network-request-failed')),
        isA<NetworkUnavailable>(),
      );
    });

    test('maps Firestore codes', () {
      FirebaseException fs(String code) =>
          FirebaseException(plugin: 'cloud_firestore', code: code);
      expect(mapError(fs('permission-denied')), isA<PermissionDenied>());
      expect(mapError(fs('unavailable')), isA<NetworkUnavailable>());
      expect(mapError(fs('aborted')), isA<ConflictFailure>());
      expect(mapError(fs('failed-precondition')), isA<IndexNotReadyFailure>());
      expect(mapError(fs('not-found')), isA<NotFoundFailure>());
      expect(
        mapError(fs('weird')),
        isA<UnknownFailure>().having(
          (f) => f.debugCode,
          'debugCode',
          'firestore/weird',
        ),
      );
    });

    test('passes failures through and wraps unknown errors', () {
      const failure = DuplicateBarcodeFailure('123');
      expect(mapError(failure), same(failure));
      expect(mapError(StateError('x')), isA<UnknownFailure>());
    });

    test('guardFailure rethrows as Failure', () async {
      await expectLater(
        guardFailure<void>(
          () async => throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
        throwsA(isA<PermissionDenied>()),
      );
    });
  });

  group('AppLogger.redact', () {
    test('masks e-mails and long numbers', () {
      expect(
        AppLogger.redact('user juan.dc+1@gmail.com phone 09171234567'),
        'user <email> phone <number>',
      );
    });
  });
}
