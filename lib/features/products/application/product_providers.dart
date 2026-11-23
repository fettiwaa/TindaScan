import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/products/domain/product_query.dart';
import 'package:tindascan/shared/models/product.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// Current filters on the product list.
class ProductQueryNotifier extends Notifier<ProductQuery> {
  @override
  ProductQuery build() => const ProductQuery();

  // ignore: use_setters_to_change_properties
  void update(ProductQuery query) => state = query;
}

final productQueryProvider =
    NotifierProvider.autoDispose<ProductQueryNotifier, ProductQuery>(
      ProductQueryNotifier.new,
    );

/// Accumulated pages of the product list.
@immutable
class ProductListState {
  const ProductListState({
    required this.items,
    required this.cursor,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<Product> items;
  final Object? cursor;
  final bool hasMore;
  final bool loadingMore;
  final Object? loadMoreError;

  ProductListState copyWith({
    bool? loadingMore,
    Object? loadMoreError,
    bool clearError = false,
  }) => ProductListState(
    items: items,
    cursor: cursor,
    hasMore: hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: clearError ? null : (loadMoreError ?? this.loadMoreError),
  );
}

/// Paginated product list that refetches when the query changes.
class ProductListController extends AsyncNotifier<ProductListState> {
  @override
  Future<ProductListState> build() async {
    final query = ref.watch(productQueryProvider);
    final page = await ref.watch(productRepositoryProvider).fetchPage(query);
    return ProductListState(
      items: page.items,
      cursor: page.cursor,
      hasMore: page.hasMore,
    );
  }

  /// Loads the next page (no-op while loading or at the end).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    final repo = ref.read(productRepositoryProvider);
    final query = ref.read(productQueryProvider);
    state = AsyncData(current.copyWith(loadingMore: true, clearError: true));
    try {
      final page = await repo.fetchPage(query, after: current.cursor);
      if (!ref.mounted) return;
      state = AsyncData(
        ProductListState(
          items: [...current.items, ...page.items],
          cursor: page.cursor,
          hasMore: page.hasMore,
        ),
      );
    } on Object catch (error) {
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(loadingMore: false, loadMoreError: error),
      );
    }
  }
}

final productListProvider =
    AsyncNotifierProvider.autoDispose<ProductListController, ProductListState>(
      ProductListController.new,
    );

/// Live single product (detail, edit, stock screens).
final productByIdProvider = StreamProvider.autoDispose.family<Product?, String>(
  (ref, id) => ref.watch(productRepositoryProvider).watchProduct(id),
);

/// Create / update / archive actions for the owner.
class ProductEditController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Saves [product] (create when `product.id` is empty). Returns the id,
  /// or null on failure (see `state.error`).
  Future<String?> save(Product product, {String initialStockNote = ''}) async {
    final repo = ref.read(productRepositoryProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return null;
    state = const AsyncLoading();
    String? id;
    final result = await AsyncValue.guard(() async {
      if (product.id.isEmpty) {
        id = await repo.createProduct(
          product,
          by: user,
          initialStockNote: initialStockNote,
        );
      } else {
        await repo.updateProduct(product);
        id = product.id;
      }
    });
    if (ref.mounted) state = result;
    return result.hasError ? null : id;
  }

  Future<bool> setActive(String id, {required bool active}) async {
    final repo = ref.read(productRepositoryProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => repo.setActive(id, active: active),
    );
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

final productEditControllerProvider =
    AsyncNotifierProvider.autoDispose<ProductEditController, void>(
      ProductEditController.new,
    );
