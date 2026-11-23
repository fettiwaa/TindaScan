import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/user_role.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// Live staff list for the owner (closed when the screen leaves).
final staffListProvider = StreamProvider.autoDispose<List<AppUser>>(
  (ref) => ref.watch(userRepositoryProvider).watchStaff(),
);

/// Owner-only staff management actions.
class StaffController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Creates the Auth account (secondary app) and its `users` profile.
  /// Returns true on success.
  Future<bool> createStaff({
    required String name,
    required String email,
    required String password,
  }) async {
    final auth = ref.read(authRepositoryProvider);
    final users = ref.read(userRepositoryProvider);
    final normalizedEmail = email.trim().toLowerCase();
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => auth.createStaffAccount(
        email: normalizedEmail,
        password: password,
        onCreated: (uid) => users.createStaffProfile(
          AppUser(
            uid: uid,
            name: name.trim(),
            email: normalizedEmail,
            role: UserRole.staff,
            active: true,
          ),
        ),
      ),
    );
    if (ref.mounted) state = result;
    return !result.hasError;
  }

  /// Activates or deactivates a staff account. Deactivated staff are signed
  /// out on their device and blocked by the security rules.
  Future<void> setActive({required String uid, required bool active}) async {
    final users = ref.read(userRepositoryProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => users.setActive(uid: uid, active: active),
    );
    if (ref.mounted) state = result;
  }
}

final staffControllerProvider =
    AsyncNotifierProvider.autoDispose<StaffController, void>(
      StaffController.new,
    );
