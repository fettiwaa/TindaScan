import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/features/auth/data/firebase_auth_repository.dart';
import 'package:tindascan/features/auth/data/firestore_user_repository.dart';
import 'package:tindascan/features/dashboard/data/firestore_stats_repository.dart';
import 'package:tindascan/features/products/data/firestore_product_repository.dart';
import 'package:tindascan/features/sales/application/lost_sales_log.dart';
import 'package:tindascan/features/sales/data/firestore_sales_repository.dart';
import 'package:tindascan/features/settings/data/firestore_settings_repository.dart';
import 'package:tindascan/features/stock/data/firestore_stock_repository.dart';
import 'package:tindascan/shared/providers/firebase_providers.dart';
import 'package:tindascan/shared/repositories/auth_repository.dart';
import 'package:tindascan/shared/repositories/product_repository.dart';
import 'package:tindascan/shared/repositories/sales_repository.dart';
import 'package:tindascan/shared/repositories/settings_repository.dart';
import 'package:tindascan/shared/repositories/stats_repository.dart';
import 'package:tindascan/shared/repositories/stock_repository.dart';
import 'package:tindascan/shared/repositories/user_repository.dart';

/// Repository injection points. Override these in tests with fakes/mocks
/// (or override [firestoreProvider] with `FakeFirebaseFirestore`).
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(
    ref.watch(firebaseAuthProvider),
    secondaryAuthFactory,
  ),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => FirestoreUserRepository(ref.watch(firestoreProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => FirestoreSettingsRepository(ref.watch(firestoreProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => FirestoreProductRepository(ref.watch(firestoreProvider)),
);

final salesRepositoryProvider = Provider<SalesRepository>(
  (ref) => FirestoreSalesRepository(
    ref.watch(firestoreProvider),
    onSyncLost: (sale) => ref.read(lostSalesProvider.notifier).record(sale),
  ),
);

final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => FirestoreStockRepository(ref.watch(firestoreProvider)),
);

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => FirestoreStatsRepository(ref.watch(firestoreProvider)),
);
