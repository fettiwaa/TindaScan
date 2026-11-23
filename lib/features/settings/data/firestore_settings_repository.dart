import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/core/errors/error_mapper.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/store_settings.dart';
import 'package:tindascan/shared/repositories/settings_repository.dart';

/// [SettingsRepository] backed by Cloud Firestore.
class FirestoreSettingsRepository implements SettingsRepository {
  FirestoreSettingsRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, Object?>> get _setupRef =>
      _db.collection(FirestorePaths.settings).doc(FirestorePaths.setupDoc);

  DocumentReference<Map<String, Object?>> get _storeRef =>
      _db.collection(FirestorePaths.settings).doc(FirestorePaths.storeDoc);

  /// Read cost: 1 read. Readable without sign-in (contains only a flag).
  /// Prefers the server so a stale cache cannot reopen the setup flow.
  @override
  Future<bool> isSetupCompleted() => guardFailure(() async {
    final snap = await _setupRef.get();
    return snap.data()?[SettingsFields.completed] == true;
  });

  /// Uses a batch so the profile, store settings and setup flag land
  /// together. The rules use `existsAfter`/`getAfter` to verify this exact
  /// combination and reject it once `settings/setup` exists, which makes the
  /// setup one-time even if two devices race.
  @override
  Future<void> completeOwnerSetup({
    required AppUser owner,
    required StoreSettings store,
  }) => guardFailure(() async {
    final batch = _db.batch()
      ..set(_db.collection(FirestorePaths.users).doc(owner.uid), {
        ...owner.toMap(),
        UserFields.createdAt: FieldValue.serverTimestamp(),
        UserFields.updatedAt: FieldValue.serverTimestamp(),
      })
      ..set(_storeRef, {
        ...store.toMap(),
        SettingsFields.updatedAt: FieldValue.serverTimestamp(),
      })
      ..set(_setupRef, {
        SettingsFields.completed: true,
        SettingsFields.completedAt: FieldValue.serverTimestamp(),
      });
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      // A denied batch here almost always means setup already happened.
      if (e.code == 'permission-denied') {
        throw const SetupAlreadyCompletedFailure();
      }
      rethrow;
    }
  });

  /// Read cost: 1 read on listen + 1 per change.
  @override
  Stream<StoreSettings> watchStore() => _storeRef
      .snapshots()
      .map((snap) {
        final data = snap.data();
        return data == null
            ? StoreSettings.fallback
            : StoreSettings.fromMap(data);
      })
      .handleError((Object e) => throw mapError(e));

  @override
  Future<void> updateStore(StoreSettings settings) => guardFailure(
    () => _storeRef.set({
      ...settings.toMap(),
      SettingsFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)),
  );
}
