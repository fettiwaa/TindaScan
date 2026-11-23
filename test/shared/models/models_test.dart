import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/store_settings.dart';
import 'package:tindascan/shared/models/user_role.dart';

void main() {
  group('AppUser', () {
    test('parses a Firestore map null-safely', () {
      final user = AppUser.fromMap('u1', {
        'name': 'Juan',
        'email': 'juan@x.ph',
        'role': 'staff',
        'active': true,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026)),
      });
      expect(user.role, UserRole.staff);
      expect(user.createdAt, DateTime.utc(2026));
    });

    test(
      'unknown or missing role falls back to staff; missing active is false',
      () {
        final user = AppUser.fromMap('u1', const {'role': 'admin'});
        expect(user.role, UserRole.staff);
        expect(user.active, isFalse);
        expect(user.name, '');
      },
    );

    test('equality and copyWith', () {
      const a = AppUser(
        uid: 'u',
        name: 'A',
        email: 'a@x.ph',
        role: UserRole.owner,
        active: true,
      );
      expect(a.copyWith(), a);
      expect(a.copyWith(active: false).active, isFalse);
      expect(a.copyWith(name: 'B') == a, isFalse);
    });
  });

  group('StoreSettings', () {
    test('round-trips through a map', () {
      const s = StoreSettings(storeName: 'Store', defaultLowStockThreshold: 7);
      expect(StoreSettings.fromMap(s.toMap()), s);
    });
  });
}
