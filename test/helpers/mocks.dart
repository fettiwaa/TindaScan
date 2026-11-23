import 'package:mocktail/mocktail.dart';

import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/store_settings.dart';
import 'package:tindascan/shared/models/user_role.dart';
import 'package:tindascan/shared/repositories/auth_repository.dart';
import 'package:tindascan/shared/repositories/settings_repository.dart';
import 'package:tindascan/shared/repositories/user_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

const testOwner = AppUser(
  uid: 'owner-1',
  name: 'Aling Nena',
  email: 'nena@example.com',
  role: UserRole.owner,
  active: true,
);

const testStaff = AppUser(
  uid: 'staff-1',
  name: 'Juan',
  email: 'juan@example.com',
  role: UserRole.staff,
  active: true,
);

/// Registers fallback values needed by `any()` matchers.
void registerTestFallbacks() {
  registerFallbackValue(testOwner);
  registerFallbackValue(StoreSettings.fallback);
}
