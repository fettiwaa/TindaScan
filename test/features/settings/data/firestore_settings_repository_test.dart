import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/features/settings/data/firestore_settings_repository.dart';
import 'package:tindascan/shared/models/store_settings.dart';
import 'package:tindascan/shared/models/user_role.dart';

import '../../../helpers/mocks.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreSettingsRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreSettingsRepository(db);
  });

  test('setup is not completed on a fresh project', () async {
    expect(await repo.isSetupCompleted(), isFalse);
  });

  test('completeOwnerSetup writes owner, store and flag together', () async {
    await repo.completeOwnerSetup(
      owner: testOwner,
      store: const StoreSettings(storeName: 'Aling Nena Store'),
    );

    expect(await repo.isSetupCompleted(), isTrue);
    final owner = await db
        .collection(FirestorePaths.users)
        .doc(testOwner.uid)
        .get();
    expect(owner.data()?[UserFields.role], UserRole.owner.value);
    expect(owner.data()?[UserFields.active], isTrue);

    final store = await repo.watchStore().first;
    expect(store.storeName, 'Aling Nena Store');
  });

  test('watchStore falls back when no document exists', () async {
    expect(await repo.watchStore().first, StoreSettings.fallback);
  });

  test('updateStore merges new values', () async {
    await repo.updateStore(
      const StoreSettings(
        storeName: 'Sari-Sari ni Juan',
        defaultLowStockThreshold: 3,
      ),
    );
    final store = await repo.watchStore().first;
    expect(store.storeName, 'Sari-Sari ni Juan');
    expect(store.defaultLowStockThreshold, 3);
  });
}
