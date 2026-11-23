import 'package:firebase_auth/firebase_auth.dart';

import 'package:tindascan/core/errors/failure.dart';

/// Converts any thrown object into a [Failure].
///
/// Firebase error codes reference:
/// - Auth: https://firebase.google.com/docs/reference/js/auth#autherrorcodes
/// - Firestore: gRPC status codes (permission-denied, unavailable, ...).
Failure mapError(Object error) {
  if (error is Failure) return error;
  if (error is FirebaseAuthException) return _mapAuth(error.code);
  if (error is FirebaseException) return _mapFirestore(error.code);
  return const UnknownFailure();
}

Failure _mapAuth(String code) => switch (code) {
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' ||
  'invalid-login-credentials' => const AuthFailure(
    AuthFailureReason.invalidCredentials,
  ),
  'email-already-in-use' => const AuthFailure(
    AuthFailureReason.emailAlreadyInUse,
  ),
  'weak-password' => const AuthFailure(AuthFailureReason.weakPassword),
  'invalid-email' => const AuthFailure(AuthFailureReason.invalidEmail),
  'user-disabled' => const AuthFailure(AuthFailureReason.accountDisabled),
  'requires-recent-login' => const AuthFailure(
    AuthFailureReason.requiresRecentLogin,
  ),
  'too-many-requests' => const RateLimitFailure(),
  'network-request-failed' => const NetworkUnavailable(),
  _ => UnknownFailure('auth/$code'),
};

Failure _mapFirestore(String code) => switch (code) {
  'permission-denied' || 'unauthenticated' => const PermissionDenied(),
  'not-found' => const NotFoundFailure(),
  'unavailable' || 'deadline-exceeded' => const NetworkUnavailable(),
  'aborted' => const ConflictFailure(),
  'failed-precondition' => const IndexNotReadyFailure(),
  'resource-exhausted' => const RateLimitFailure(),
  _ => UnknownFailure('firestore/$code'),
};

/// Runs [action] and rethrows any error as a [Failure].
Future<T> guardFailure<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on Object catch (error) {
    throw mapError(error);
  }
}
