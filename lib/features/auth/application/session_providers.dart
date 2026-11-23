import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/features/auth/domain/session.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';
import 'package:tindascan/shared/repositories/auth_repository.dart';
import 'package:tindascan/shared/repositories/settings_repository.dart';
import 'package:tindascan/shared/repositories/user_repository.dart';

/// Signed-in uid stream from Firebase Auth.
final authUidProvider = StreamProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).uidChanges(),
);

/// Holds the reason for the last forced sign-out (e.g. deactivation).
class SignOutReasonNotifier extends Notifier<SignOutReason?> {
  @override
  SignOutReason? build() => null;

  void set(SignOutReason reason) => state = reason;

  void clear() => state = null;
}

final signOutReasonProvider =
    NotifierProvider<SignOutReasonNotifier, SignOutReason?>(
      SignOutReasonNotifier.new,
    );

/// The app-wide [Session]. The router listens to this to apply role guards.
///
/// It combines the Auth uid with the live `users/{uid}` document, so a
/// deactivation by the owner takes effect immediately on the staff device:
/// the profile stream emits `active: false` and we sign out.
final sessionProvider = StreamProvider<Session>((ref) {
  final uid = ref.watch(authUidProvider);
  final auth = ref.watch(authRepositoryProvider);
  final users = ref.watch(userRepositoryProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  final reasons = ref.read(signOutReasonProvider.notifier);

  return switch (uid) {
    AsyncData(value: final String id) => _signedIn(
      id,
      auth: auth,
      users: users,
      settings: settings,
      reasons: reasons,
    ),
    AsyncData() => _signedOut(settings),
    AsyncError(:final error, :final stackTrace) => Stream.error(
      error,
      stackTrace,
    ),
    _ => Stream.value(const SessionLoading()),
  };
});

/// Convenience: the signed-in user, or `null`.
final currentUserProvider = Provider<AppUser?>((ref) {
  final session = ref.watch(sessionProvider).value;
  return session is SessionSignedIn ? session.user : null;
});

/// Used only while signed in without a profile: if the flag cannot be read
/// we assume setup is done, which leads to the account-issue screen.
Future<bool> _setupCompleted(SettingsRepository settings) async {
  try {
    return await settings.isSetupCompleted();
  } on Object {
    return true;
  }
}

/// Signed out: decide between login and first-run setup. A failed read is
/// reported, never guessed; otherwise a misconfigured project would show a
/// login screen that nobody can get past.
Stream<Session> _signedOut(SettingsRepository settings) async* {
  try {
    yield SessionSignedOut(setupCompleted: await settings.isSetupCompleted());
  } on Object catch (error) {
    yield SessionSetupCheckFailed(error);
  }
}

Stream<Session> _signedIn(
  String uid, {
  required AuthRepository auth,
  required UserRepository users,
  required SettingsRepository settings,
  required SignOutReasonNotifier reasons,
}) async* {
  await for (final user in users.watchUser(uid)) {
    if (user == null) {
      yield SessionMissingProfile(
        uid: uid,
        setupCompleted: await _setupCompleted(settings),
      );
    } else if (!user.active) {
      reasons.set(SignOutReason.deactivated);
      yield const SessionLoading();
      await auth.signOut();
    } else {
      yield SessionSignedIn(user);
    }
  }
}
