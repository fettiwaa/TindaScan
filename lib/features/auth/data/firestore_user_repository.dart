import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/core/errors/error_mapper.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/user_role.dart';
import 'package:tindascan/shared/repositories/user_repository.dart';

/// [UserRepository] backed by Cloud Firestore.
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, Object?>> get _users =>
      _db.collection(FirestorePaths.users);

  /// Read cost: 1 read on listen + 1 per change to this single document.
  @override
  Stream<AppUser?> watchUser(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((snap) {
        final data = snap.data();
        return data == null ? null : AppUser.fromMap(snap.id, data);
      })
      .handleError((Object e) => throw mapError(e));

  /// Read cost: at most [AppConstants.maxStaffListSize] reads on listen.
  /// Index: users(role ASC, createdAt DESC).
  @override
  Stream<List<AppUser>> watchStaff() => _users
      .where(UserFields.role, isEqualTo: UserRole.staff.value)
      .orderBy(UserFields.createdAt, descending: true)
      .limit(AppConstants.maxStaffListSize)
      .snapshots()
      .map(
        (query) => [
          for (final doc in query.docs) AppUser.fromMap(doc.id, doc.data()),
        ],
      )
      .handleError((Object e) => throw mapError(e));

  @override
  Future<void> createStaffProfile(AppUser staff) => guardFailure(
    () => _users.doc(staff.uid).set({
      ...staff.toMap(),
      UserFields.createdAt: FieldValue.serverTimestamp(),
      UserFields.updatedAt: FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> setActive({required String uid, required bool active}) =>
      guardFailure(
        () => _users.doc(uid).update({
          UserFields.active: active,
          UserFields.updatedAt: FieldValue.serverTimestamp(),
        }),
      );

  @override
  Future<void> updateName({required String uid, required String name}) =>
      guardFailure(
        () => _users.doc(uid).update({
          UserFields.name: name.trim(),
          UserFields.updatedAt: FieldValue.serverTimestamp(),
        }),
      );
}
