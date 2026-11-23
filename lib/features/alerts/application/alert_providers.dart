import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/app_logger.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/features/alerts/application/alert_service.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// Active products at or below their low-stock threshold.
final lowStockProductsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).lowStock(),
);

/// Products expired or expiring within the warning window.
final expiringProductsProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) {
  final now = ref.watch(clockProvider)();
  return ref
      .watch(productRepositoryProvider)
      .expiringBefore(
        now.add(const Duration(days: AppConstants.expiryWarningDays)),
      );
});

/// Products whose stock went negative (offline overselling).
final negativeStockProductsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).negativeStock(),
);

/// Badge count for the home screen (cheap aggregate query).
final lowStockCountProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(productRepositoryProvider).countLowStock(),
);

/// Checks low stock once per app session for the owner (not auto-disposed),
/// so it costs at most one low-stock query per launch. The rules for who is
/// notified and how often live in [AlertService].
final lowStockNotificationProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null || !user.isOwner) return 0;
  try {
    final products = await ref.read(productRepositoryProvider).lowStock();
    return ref.read(alertServiceProvider).evaluate(products);
  } on Object catch (error, stack) {
    // Best-effort; never break the app shell.
    AppLogger.error('Low-stock check', error, stack);
    return 0;
  }
});
