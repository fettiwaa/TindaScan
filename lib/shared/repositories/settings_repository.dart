import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/store_settings.dart';

/// Access to the `settings` collection. All methods throw a `Failure`.
abstract interface class SettingsRepository {
  /// Whether the one-time owner setup has been completed.
  Future<bool> isSetupCompleted();

  /// Atomically writes the owner profile, the store settings and the
  /// `settings/setup` flag. The rules allow this exactly once.
  Future<void> completeOwnerSetup({
    required AppUser owner,
    required StoreSettings store,
  });

  Stream<StoreSettings> watchStore();

  Future<void> updateStore(StoreSettings settings);
}
