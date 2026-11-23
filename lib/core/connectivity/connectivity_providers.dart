import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of connectivity changes (overridable in tests).
final connectivityStreamProvider = Provider<Stream<bool>>((ref) async* {
  final connectivity = Connectivity();
  bool online(List<ConnectivityResult> r) =>
      r.any((result) => result != ConnectivityResult.none);
  yield online(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(online);
});

/// Whether the device has a network connection.
///
/// Known risk: "connected" only means a network interface is up (e.g. Wi-Fi
/// without internet still reports online). Checkout therefore also falls
/// back to the offline path when a transaction fails with a network error.
final isOnlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityStreamProvider),
);
