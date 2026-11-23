import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/features/auth/application/auth_controllers.dart';
import 'package:tindascan/features/auth/application/staff_controllers.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/user_role.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository auth;
  late MockUserRepository users;
  late MockSettingsRepository settings;

  setUpAll(registerTestFallbacks);

  setUp(() {
    auth = MockAuthRepository();
    users = MockUserRepository();
    settings = MockSettingsRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        userRepositoryProvider.overrideWithValue(users),
        settingsRepositoryProvider.overrideWithValue(settings),
      ],
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
    return container;
  }

  group('LoginController', () {
    test('exposes the failure on wrong credentials', () async {
      when(
        () => auth.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure(AuthFailureReason.invalidCredentials));
      final container = makeContainer();
      final sub = container.listen(loginControllerProvider, (_, _) {});
      addTearDown(sub.close);

      await container
          .read(loginControllerProvider.notifier)
          .signIn(email: 'a@b.ph', password: 'wrong');

      expect(container.read(loginControllerProvider).error, isA<AuthFailure>());
    });
  });

  group('SetupController', () {
    test('registers the owner with a normalized e-mail', () async {
      when(settings.isSetupCompleted).thenAnswer((_) async => false);
      when(
        () => auth.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => 'new-owner');
      when(
        () => settings.completeOwnerSetup(
          owner: any(named: 'owner'),
          store: any(named: 'store'),
        ),
      ).thenAnswer((_) async {});
      final container = makeContainer();
      final sub = container.listen(setupControllerProvider, (_, _) {});
      addTearDown(sub.close);

      await container
          .read(setupControllerProvider.notifier)
          .completeSetup(
            storeName: ' Aling Nena Store ',
            ownerName: 'Nena',
            email: ' Nena@Example.com ',
            password: 'password123',
          );

      final captured =
          verify(
                () => settings.completeOwnerSetup(
                  owner: captureAny(named: 'owner'),
                  store: any(named: 'store'),
                ),
              ).captured.single
              as AppUser;
      expect(captured.uid, 'new-owner');
      expect(captured.email, 'nena@example.com');
      expect(captured.role, UserRole.owner);
      expect(container.read(setupControllerProvider).hasError, isFalse);
    });

    test('refuses when setup is already done', () async {
      when(settings.isSetupCompleted).thenAnswer((_) async => true);
      final container = makeContainer();
      final sub = container.listen(setupControllerProvider, (_, _) {});
      addTearDown(sub.close);

      await container
          .read(setupControllerProvider.notifier)
          .completeSetup(
            storeName: 'S',
            ownerName: 'N',
            email: 'n@x.ph',
            password: 'password123',
          );

      expect(
        container.read(setupControllerProvider).error,
        isA<SetupAlreadyCompletedFailure>(),
      );
      verifyNever(
        () => auth.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('deletes the new account if writing the profile fails', () async {
      when(settings.isSetupCompleted).thenAnswer((_) async => false);
      when(
        () => auth.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => 'new-owner');
      when(
        () => settings.completeOwnerSetup(
          owner: any(named: 'owner'),
          store: any(named: 'store'),
        ),
      ).thenThrow(const SetupAlreadyCompletedFailure());
      when(auth.deleteCurrentAccount).thenAnswer((_) async {});
      final container = makeContainer();
      final sub = container.listen(setupControllerProvider, (_, _) {});
      addTearDown(sub.close);

      await container
          .read(setupControllerProvider.notifier)
          .completeSetup(
            storeName: 'S',
            ownerName: 'N',
            email: 'n@x.ph',
            password: 'password123',
          );

      verify(auth.deleteCurrentAccount).called(1);
      expect(container.read(setupControllerProvider).hasError, isTrue);
    });
  });

  group('StaffController', () {
    test('creates the account and writes a staff profile', () async {
      when(
        () => auth.createStaffAccount(
          email: any(named: 'email'),
          password: any(named: 'password'),
          onCreated: any(named: 'onCreated'),
        ),
      ).thenAnswer((invocation) async {
        final onCreated =
            invocation.namedArguments[#onCreated]
                as Future<void> Function(String);
        await onCreated('staff-9');
        return 'staff-9';
      });
      when(() => users.createStaffProfile(any())).thenAnswer((_) async {});
      final container = makeContainer();
      final sub = container.listen(staffControllerProvider, (_, _) {});
      addTearDown(sub.close);

      final ok = await container
          .read(staffControllerProvider.notifier)
          .createStaff(
            name: ' Juan ',
            email: 'Juan@X.ph',
            password: 'password1',
          );

      expect(ok, isTrue);
      final profile =
          verify(() => users.createStaffProfile(captureAny())).captured.single
              as AppUser;
      expect(profile.uid, 'staff-9');
      expect(profile.name, 'Juan');
      expect(profile.email, 'juan@x.ph');
      expect(profile.role, UserRole.staff);
      expect(profile.active, isTrue);
    });

    test('setActive forwards to the repository', () async {
      when(
        () => users.setActive(
          uid: any(named: 'uid'),
          active: any(named: 'active'),
        ),
      ).thenAnswer((_) async {});
      final container = makeContainer();
      final sub = container.listen(staffControllerProvider, (_, _) {});
      addTearDown(sub.close);

      await container
          .read(staffControllerProvider.notifier)
          .setActive(uid: 'staff-1', active: false);

      verify(() => users.setActive(uid: 'staff-1', active: false)).called(1);
    });
  });
}
