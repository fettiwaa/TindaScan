import 'package:tindascan/shared/models/app_user.dart';

/// Access to `users/{uid}` profiles. All methods throw a `Failure` on error.
abstract interface class UserRepository {
  /// Live profile for [uid]; emits `null` if the document does not exist.
  Stream<AppUser?> watchUser(String uid);

  /// Live list of staff accounts (owner only), newest first, capped.
  Stream<List<AppUser>> watchStaff();

  /// Writes the profile of a freshly created staff account.
  Future<void> createStaffProfile(AppUser staff);

  Future<void> setActive({required String uid, required bool active});

  Future<void> updateName({required String uid, required String name});
}
