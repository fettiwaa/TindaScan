import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/shared/models/store_settings.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// Store settings, available once someone is signed in.
final storeSettingsProvider = StreamProvider.autoDispose<StoreSettings>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(StoreSettings.fallback);
  return ref.watch(settingsRepositoryProvider).watchStore();
});
