/// Authentication operations (Firebase Auth behind an interface).
///
/// All methods throw a `Failure` on error.
abstract interface class AuthRepository {
  /// Emits the signed-in user's uid, or `null` when signed out.
  Stream<String?> uidChanges();

  /// The uid of the signed-in user, if any.
  String? get currentUid;

  Future<void> signIn({required String email, required String password});

  /// Creates an account and signs it in. Returns the new uid.
  Future<String> register({required String email, required String password});

  /// Creates a staff account on a secondary Firebase app so the current
  /// (owner) session is untouched, then runs [onCreated] with the new uid
  /// (e.g. to write the profile). If [onCreated] fails the new account is
  /// deleted again so no orphan login remains. Returns the new uid.
  Future<String> createStaffAccount({
    required String email,
    required String password,
    required Future<void> Function(String uid) onCreated,
  });

  /// Deletes the currently signed-in account (used to roll back a failed
  /// owner setup so no orphan account remains).
  Future<void> deleteCurrentAccount();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
