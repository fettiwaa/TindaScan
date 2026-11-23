import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/store_settings.dart';
import 'package:tindascan/shared/models/user_role.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// Login screen logic. `state` reflects the in-flight sign-in request.
class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) async {
    final auth = ref.read(authRepositoryProvider);
    ref.read(signOutReasonProvider.notifier).clear();
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => auth.signIn(email: email, password: password),
    );
    if (ref.mounted) state = result;
  }

  /// Returns true when the reset e-mail was sent.
  Future<bool> sendPasswordReset(String email) async {
    final auth = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => auth.sendPasswordReset(email));
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

final loginControllerProvider =
    AsyncNotifierProvider.autoDispose<LoginController, void>(
      LoginController.new,
    );

/// One-time owner registration.
class SetupController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> completeSetup({
    required String storeName,
    required String ownerName,
    required String email,
    required String password,
  }) async {
    // Capture dependencies first: the router may dispose this screen as soon
    // as the profile appears, before this method returns.
    final auth = ref.read(authRepositoryProvider);
    final settings = ref.read(settingsRepositoryProvider);
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      if (await settings.isSetupCompleted()) {
        throw const SetupAlreadyCompletedFailure();
      }
      // Firebase Auth lower-cases e-mails in the ID token; the rules compare
      // the profile e-mail against it, so normalise the same way.
      final normalizedEmail = email.trim().toLowerCase();
      final uid = await auth.register(
        email: normalizedEmail,
        password: password,
      );
      try {
        await settings.completeOwnerSetup(
          owner: AppUser(
            uid: uid,
            name: ownerName.trim(),
            email: normalizedEmail,
            role: UserRole.owner,
            active: true,
          ),
          store: StoreSettings(storeName: storeName.trim()),
        );
      } on Object {
        // Do not leave an Auth account without a profile behind.
        try {
          await auth.deleteCurrentAccount();
        } on Object {
          // Best effort; the original error is more useful to the user.
        }
        rethrow;
      }
    });
    if (ref.mounted) state = result;
  }
}

final setupControllerProvider =
    AsyncNotifierProvider.autoDispose<SetupController, void>(
      SetupController.new,
    );

/// Signed-in user's own profile actions.
class ProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateName(String name) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final users = ref.read(userRepositoryProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => users.updateName(uid: user.uid, name: name),
    );
    if (ref.mounted) state = result;
  }

  Future<void> signOut() async {
    final auth = ref.read(authRepositoryProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(auth.signOut);
    if (ref.mounted) state = result;
  }
}

final profileControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, void>(
      ProfileController.new,
    );
