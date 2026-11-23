import 'package:flutter/foundation.dart';

import 'package:tindascan/shared/models/app_user.dart';

/// Why the user was signed out (shown on the login screen).
enum SignOutReason {
  deactivated,

  /// The server refused to read the user's own profile (e.g. a login saved
  /// from a different Firebase project, or a revoked account).
  sessionRejected,
}

/// The authentication + authorization state the router reacts to.
@immutable
sealed class Session {
  const Session();
}

/// Still resolving auth state or the profile document.
final class SessionLoading extends Session {
  const SessionLoading();
}

/// Nobody is signed in.
final class SessionSignedOut extends Session {
  const SessionSignedOut({required this.setupCompleted});

  /// False only before the very first owner has registered.
  final bool setupCompleted;

  @override
  bool operator ==(Object other) =>
      other is SessionSignedOut && other.setupCompleted == setupCompleted;

  @override
  int get hashCode => setupCompleted.hashCode;
}

/// Signed out, and the `settings/setup` flag could not be read (no
/// connection, rules not deployed, wrong project). We cannot know whether to
/// show login or first-run setup, so the UI shows the error with a retry.
final class SessionSetupCheckFailed extends Session {
  const SessionSetupCheckFailed(this.error);

  final Object error;

  @override
  bool operator ==(Object other) =>
      other is SessionSetupCheckFailed && other.error == error;

  @override
  int get hashCode => error.hashCode;
}

/// Signed in to Auth but `users/{uid}` does not exist (yet). Happens briefly
/// during owner setup, or if a profile write failed.
final class SessionMissingProfile extends Session {
  const SessionMissingProfile({
    required this.uid,
    required this.setupCompleted,
  });

  final String uid;
  final bool setupCompleted;

  @override
  bool operator ==(Object other) =>
      other is SessionMissingProfile &&
      other.uid == uid &&
      other.setupCompleted == setupCompleted;

  @override
  int get hashCode => Object.hash(uid, setupCompleted);
}

/// Signed in with an active profile.
final class SessionSignedIn extends Session {
  const SessionSignedIn(this.user);

  final AppUser user;

  @override
  bool operator ==(Object other) =>
      other is SessionSignedIn && other.user == user;

  @override
  int get hashCode => user.hashCode;
}
