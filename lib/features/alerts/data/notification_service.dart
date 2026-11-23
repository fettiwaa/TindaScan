import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/shared/models/product.dart';

/// Shows device notifications (behind an interface for tests).
abstract interface class AlertNotifier {
  Future<void> showLowStock(List<Product> products, AppLocalizations l10n);
}

/// [AlertNotifier] using flutter_local_notifications.
class LocalNotificationService implements AlertNotifier {
  static const String _channelId = 'low_stock';
  static const String _icon = '@mipmap/ic_launcher';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
        iOS: DarwinInitializationSettings(),
      ),
    );
    // Android 13+ requires a runtime permission for notifications.
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  @override
  Future<void> showLowStock(
    List<Product> products,
    AppLocalizations l10n,
  ) async {
    if (products.isEmpty) return;
    await _ensureReady();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        l10n.notificationChannelName,
        channelDescription: l10n.notificationChannelDescription,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    for (final product in products) {
      await _plugin.show(
        // Stable id per product: a newer alert replaces the older one.
        id: product.id.hashCode & 0x7fffffff,
        title: l10n.notificationLowStockTitle(product.name),
        body: l10n.notificationLowStockBody(product.stockQty),
        notificationDetails: details,
      );
    }
  }
}

final alertNotifierProvider = Provider<AlertNotifier>(
  (ref) => LocalNotificationService(),
);
