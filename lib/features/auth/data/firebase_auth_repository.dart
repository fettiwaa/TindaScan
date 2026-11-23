import 'package:firebase_auth/firebase_auth.dart';

import 'package:tindascan/core/errors/error_mapper.dart';
import 'package:tindascan/shared/repositories/auth_repository.dart';

/// Provides a [FirebaseAuth] bound to a *secondary* FirebaseApp.
typedef SecondaryAuthFactory = Future<FirebaseAuth> Function();

/// [AuthRepository] backed by Firebase Authentication.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._secondaryAuth);

  final FirebaseAuth _auth;
  final SecondaryAuthFactory _secondaryAuth;

  @override
  Stream<String?> uidChanges() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  Future<void> signIn({required String email, required String password}) =>
      guardFailure(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  @override
  Future<String> register({required String email, required String password}) =>
      guardFailure(() async {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return credential.user!.uid;
      });

  /// Spark-plan friendly staff creation: Firebase Auth signs in whoever is
  /// created on an app instance, so we create the account on a separate app
  /// and sign that instance out immediately. The owner stays signed in on the
  /// default app.
  @override
  Future<String> createStaffAccount({
    required String email,
    required String password,
    required Future<void> Function(String uid) onCreated,
  }) => guardFailure(() async {
    final secondary = await _secondaryAuth();
    try {
      final credential = await secondary.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      try {
        await onCreated(user.uid);
      } on Object {
        // Roll back: the secondary instance is still signed in as the new
        // user, so it may delete itself.
        await user.delete();
        rethrow;
      }
      return user.uid;
    } finally {
      await secondary.signOut();
    }
  });

  @override
  Future<void> deleteCurrentAccount() => guardFailure(() async {
    await _auth.currentUser?.delete();
  });

  @override
  Future<void> sendPasswordReset(String email) =>
      guardFailure(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() => guardFailure(_auth.signOut);
}
