import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/settings/application/seed_data.dart';
import 'package:tindascan/shared/models/store_settings.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// Owner settings actions.
class SettingsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> save(StoreSettings settings) async {
    final repo = ref.read(settingsRepositoryProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => repo.updateStore(settings));
    if (ref.mounted) state = result;
    return !result.hasError;
  }

  /// Debug helper: adds ~20 sample products. Returns the number added.
  Future<int?> seed({required String initialStockNote}) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(productRepositoryProvider);
    if (user == null) return null;
    state = const AsyncLoading();
    int? added;
    final result = await AsyncValue.guard(() async {
      added = await seedSampleProducts(
        repo,
        by: user,
        initialStockNote: initialStockNote,
      );
    });
    if (ref.mounted) state = result;
    return added;
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider.autoDispose<SettingsController, void>(
      SettingsController.new,
    );
