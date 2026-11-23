import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/auth/domain/session.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/replay_stream.dart';

void main() {
  late MockAuthRepository auth;
  late MockUserRepository users;
  late MockSettingsRepository settings;
  late ReplayStream<String?> uid;
  late ReplayStream<AppUser?> profile;

  setUp(() {
    auth = MockAuthRepository();
    users = MockUserRepository();
    settings = MockSettingsRepository();
    uid = ReplayStream<String?>();
    profile = ReplayStream<AppUser?>();

    when(auth.uidChanges).thenAnswer((_) => uid.stream);
    when(() => auth.signOut()).thenAnswer((_) async => uid.add(null));
    when(() => users.watchUser(any())).thenAnswer((_) => profile.stream);
    when(settings.isSetupCompleted).thenAnswer((_) async => true);
  });

  tearDown(() async {
    await uid.close();
    await profile.close();
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

  /// Waits until the session satisfies [matcher].
  Future<Session> sessionWhere(
    ProviderContainer container,
    bool Function(Session s) test,
  ) {
    final completer = Completer<Session>();
    final sub = container.listen<AsyncValue<Session>>(sessionProvider, (
      _,
      next,
    ) {
      final value = next.value;
      if (value != null && test(value) && !completer.isCompleted) {
        completer.complete(value);
      }
    }, fireImmediately: true);
    return completer.future.whenComplete(sub.close);
  }

  test('signed out reports whether setup was completed', () async {
    when(settings.isSetupCompleted).thenAnswer((_) async => false);
    final container = makeContainer();
    final future = sessionWhere(container, (s) => s is SessionSignedOut);
    await Future<void>.delayed(Duration.zero);
    uid.add(null);

    expect(await future, const SessionSignedOut(setupCompleted: false));
  });

  test('setup-flag read failure is reported, not guessed', () async {
    when(settings.isSetupCompleted).thenAnswer((_) async => throw Exception());
    final container = makeContainer();
    final future = sessionWhere(
      container,
      (s) => s is SessionSetupCheckFailed || s is SessionSignedOut,
    );
    await Future<void>.delayed(Duration.zero);
    uid.add(null);

    expect(await future, isA<SessionSetupCheckFailed>());
  });

  test('signed in with an active profile', () async {
    final container = makeContainer();
    final future = sessionWhere(container, (s) => s is SessionSignedIn);
    await Future<void>.delayed(Duration.zero);
    uid.add(testStaff.uid);
    await Future<void>.delayed(Duration.zero);
    profile.add(testStaff);

    expect(await future, const SessionSignedIn(testStaff));
    expect(container.read(currentUserProvider), testStaff);
  });

  test('missing profile is reported (not signed out)', () async {
    final container = makeContainer();
    final future = sessionWhere(container, (s) => s is SessionMissingProfile);
    await Future<void>.delayed(Duration.zero);
    uid.add('ghost');
    await Future<void>.delayed(Duration.zero);
    profile.add(null);

    expect(
      await future,
      const SessionMissingProfile(uid: 'ghost', setupCompleted: true),
    );
    verifyNever(() => auth.signOut());
  });

  test('deactivation signs the user out and records the reason', () async {
    final container = makeContainer();
    final signedIn = sessionWhere(container, (s) => s is SessionSignedIn);
    await Future<void>.delayed(Duration.zero);
    uid.add(testStaff.uid);
    await Future<void>.delayed(Duration.zero);
    profile.add(testStaff);
    await signedIn;

    final signedOut = sessionWhere(container, (s) => s is SessionSignedOut);
    profile.add(testStaff.copyWith(active: false));

    expect(await signedOut, isA<SessionSignedOut>());
    verify(() => auth.signOut()).called(1);
    expect(container.read(signOutReasonProvider), SignOutReason.deactivated);
  });
}
