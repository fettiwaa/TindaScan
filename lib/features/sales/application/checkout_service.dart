import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/connectivity/connectivity_providers.dart';
import 'package:tindascan/core/errors/app_logger.dart';
import 'package:tindascan/core/errors/error_mapper.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/core/utils/manila_time.dart';
import 'package:tindascan/features/alerts/application/alert_service.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/sales/application/cart_notifier.dart';
import 'package:tindascan/features/sales/domain/cart.dart';
import 'package:tindascan/features/sales/domain/payment.dart';
import 'package:tindascan/shared/models/app_user.dart';
import 'package:tindascan/shared/models/sale.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';
import 'package:tindascan/shared/repositories/sales_repository.dart';

/// The F-01 checkout use case (business layer), independent of Flutter
/// widgets and of Firestore.
///
/// Owns: payment validation, choosing the online transaction or the offline
/// fallback, refreshing the cart after a stock conflict, clearing it after a
/// sale, and handing the new stock levels to [AlertService].
/// Does not own: UI, Firestore APIs or document layouts (those live behind
/// [SalesRepository]).
class CheckoutService {
  CheckoutService({
    required SalesRepository sales,
    required CartNotifier cart,
    required AlertService alerts,
    required AppUser? Function() cashier,
    required bool Function() isOnline,
    required DateTime Function() clock,
  }) : _sales = sales,
       _cart = cart,
       _alerts = alerts,
       _cashier = cashier,
       _isOnline = isOnline,
       _clock = clock;

  final SalesRepository _sales;
  final CartNotifier _cart;
  final AlertService _alerts;
  final AppUser? Function() _cashier;
  final bool Function() _isOnline;
  final DateTime Function() _clock;

  Future<Sale>? _inFlight;

  /// Records [cart] as a cash sale paid with [tenderedCentavos]
  /// (contract 3 in LA2, Worksheet C).
  ///
  /// Throws [InvalidPayment] for an empty cart or when the cash does not
  /// cover the total (no network call), [PermissionDenied] without an active
  /// cashier, and otherwise the failures of [SalesRepository.createSale].
  /// A second call while one is running returns the same pending sale, so a
  /// double tap can never charge twice.
  Future<Sale> checkout(Cart cart, int tenderedCentavos) => _inFlight ??=
      _checkout(cart, tenderedCentavos).whenComplete(() => _inFlight = null);

  Future<Sale> _checkout(Cart cart, int tenderedCentavos) async {
    if (cart.isEmpty ||
        !Payment.isSufficient(
          totalCentavos: cart.totalCentavos,
          tenderedCentavos: tenderedCentavos,
        )) {
      throw const InvalidPayment();
    }
    final cashier = _cashier();
    if (cashier == null || !cashier.active) throw const PermissionDenied();

    // Stable for this cart: a retry after a lost response finds the sale
    // that already committed instead of creating a second one.
    final saleId = _cart.checkoutSaleId();
    final now = _clock();

    Sale sale;
    try {
      if (_isOnline()) {
        try {
          sale = await _sales.createSale(
            cart,
            tenderedCentavos,
            cashier: cashier,
            saleId: saleId,
            now: now,
          );
        } on NetworkUnavailable {
          // Network interface up but no internet: record offline instead.
          // Safe even if the transaction did commit: the server rejects the
          // batch's sale document as an update, so nothing applies twice.
          sale = await _sales.createSaleOffline(
            cart,
            tenderedCentavos,
            cashier: cashier,
            saleId: saleId,
            now: now,
          );
        }
      } else {
        sale = await _sales.createSaleOffline(
          cart,
          tenderedCentavos,
          cashier: cashier,
          saleId: saleId,
          now: now,
        );
      }
    } on Object catch (error) {
      final failure = mapError(error);
      if (failure is InsufficientStock ||
          failure is ProductNotFound ||
          failure is PriceChangedFailure) {
        // Another device changed the data: reload so the cashier sees it.
        try {
          await _cart.refreshFromServer();
        } on Object catch (refreshError, stack) {
          AppLogger.error('Cart refresh', refreshError, stack);
        }
      }
      throw failure;
    }

    _cart.clear();
    // Stock after this sale, from the cart's snapshot (the transaction
    // re-read it; a concurrent sale elsewhere only makes it lower, which
    // the owner's next low-stock check will catch).
    unawaited(
      _alerts.evaluate([
        for (final line in cart.lines)
          line.product.copyWith(stockQty: line.product.stockQty - line.qty),
      ]),
    );
    return sale;
  }
}

final checkoutServiceProvider = Provider<CheckoutService>(
  (ref) => CheckoutService(
    sales: ref.watch(salesRepositoryProvider),
    cart: ref.read(cartProvider.notifier),
    alerts: ref.watch(alertServiceProvider),
    cashier: () => ref.read(currentUserProvider),
    isOnline: () => ref.read(isOnlineProvider).value ?? true,
    clock: ref.watch(clockProvider),
  ),
);
