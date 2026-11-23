import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/core/constants/firestore_paths.dart';
import 'package:tindascan/features/auth/data/firestore_user_repository.dart';
import 'package:tindascan/shared/models/user_role.dart';

import '../../../helpers/mocks.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreUserRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = FirestoreUserRepository(db);
  });

  test(
    'watchUser emits null for a missing profile, then the profile',
    () async {
      final stream = repo.watchUser(testStaff.uid);
      expect(await stream.first, isNull);

      await repo.createStaffProfile(testStaff);
      final user = await repo.watchUser(testStaff.uid).first;
      expect(user?.name, testStaff.name);
      expect(user?.role, UserRole.staff);
      expect(user?.active, isTrue);
    },
  );

  test(
    'createStaffProfile writes only allowed fields with timestamps',
    () async {
      await repo.createStaffProfile(testStaff);
      final data =
          (await db.collection(FirestorePaths.users).doc(testStaff.uid).get())
              .data()!;
      expect(data.keys.toSet(), {
        UserFields.name,
        UserFields.email,
        UserFields.role,
        UserFields.active,
        UserFields.createdAt,
        UserFields.updatedAt,
      });
      expect(data[UserFields.role], 'staff');
    },
  );

  test('watchStaff lists only staff accounts', () async {
    await db.collection(FirestorePaths.users).doc(testOwner.uid).set({
      ...testOwner.toMap(),
      UserFields.createdAt: DateTime(2026),
    });
    await repo.createStaffProfile(testStaff);

    final staff = await repo.watchStaff().first;
    expect(staff.map((u) => u.uid), [testStaff.uid]);
  });

  test('setActive and updateName change the profile', () async {
    await repo.createStaffProfile(testStaff);
    await repo.setActive(uid: testStaff.uid, active: false);
    await repo.updateName(uid: testStaff.uid, name: '  Juan Dela Cruz ');

    final user = await repo.watchUser(testStaff.uid).first;
    expect(user?.active, isFalse);
    expect(user?.name, 'Juan Dela Cruz');
  });
}
