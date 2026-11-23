import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/errors/error_mapper.dart';
import 'package:tindascan/core/errors/failure.dart';
import 'package:tindascan/features/products/domain/product_validators.dart';
import 'package:tindascan/features/sales/domain/cart.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// The current sale's cart (F-01 business layer). Owns the immutable [Cart],
/// merging repeated scans into one line and blocking quantities above the
/// available stock. It does not persist anything: `CheckoutService` does,
/// and stock is checked again inside the sale transaction.
///
/// Kept alive while moving between Sell, the payment sheet and the receipt;
/// cleared after a successful sale.
class CartNotifier extends Notifier<Cart> {
  /// Idempotency key for the next checkout of *this* cart. Reset whenever the
  /// cart changes, so a retry after a lost response reuses the same sale id
  /// (and cannot double-charge), while a modified cart gets a new one.
  String? _pendingSaleId;

  @override
  Cart build() => const Cart();

  void _set(Cart cart) {
    _pendingSaleId = null;
    state = cart;
  }

  /// Looks up [barcode] and adds one unit (contract 1 in LA2, Worksheet C).
  ///
  /// Returns the updated cart. Throws a typed failure and leaves the cart
  /// unchanged when the code is malformed or unknown ([ProductNotFound] with
  /// the barcode), the product would exceed its stock ([InsufficientStock]),
  /// or the lookup fails ([NetworkUnavailable], [PermissionDenied]).
  Future<Cart> addByBarcode(String barcode) async {
    final code = ProductValidators.normalizeBarcode(barcode);
    if (ProductValidators.barcode(code) != null) {
      throw ProductNotFound(barcode: code);
    }
    final Product? product;
    try {
      product = await ref.read(productRepositoryProvider).findByBarcode(code);
    } on Object catch (error) {
      throw mapError(error);
    }
    if (product == null || !product.isActive) {
      throw ProductNotFound(barcode: code);
    }
    final failure = add(product);
    if (failure != null) throw failure;
    return state;
  }

  /// Adds [qty] units of an already-loaded product (search suggestions).
  /// Returns the failure instead of throwing so the UI can show it.
  Failure? add(Product product, {int qty = 1}) {
    try {
      _set(state.add(product, qty: qty));
      return null;
    } on Failure catch (failure) {
      return failure;
    }
  }

  Failure? setQuantity(Product product, int qty) {
    try {
      _set(state.setQuantity(product, qty));
      return null;
    } on Failure catch (failure) {
      return failure;
    }
  }

  void remove(String productId) => _set(state.remove(productId));

  void clear() => _set(const Cart());

  /// Puts back a previous cart (Undo after remove / clear).
  void restore(Cart previous) => _set(previous);

  /// Sale id to use for checkout (stable until the cart changes).
  String checkoutSaleId() =>
      _pendingSaleId ??= ref.read(salesRepositoryProvider).newSaleId();

  /// Reloads product data after a stock conflict at checkout: lines are
  /// clamped to the available stock and archived products are dropped.
  Future<void> refreshFromServer() async {
    final repo = ref.read(productRepositoryProvider);
    try {
      final fresh = <String, Product?>{};
      for (final line in state.lines) {
        fresh[line.product.id] = await repo.getProduct(line.product.id);
      }
      if (ref.mounted) _set(state.refresh(fresh));
    } on Object catch (error) {
      throw mapError(error);
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, Cart>(CartNotifier.new);
