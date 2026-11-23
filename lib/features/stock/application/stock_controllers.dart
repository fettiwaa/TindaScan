import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/stock/domain/restock.dart';
import 'package:tindascan/shared/models/stock_movement.dart';
import 'package:tindascan/shared/providers/repository_providers.dart';

/// Owner stock adjustments.
class StockAdjustController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Returns true on success.
  Future<bool> adjust({
    required String productId,
    required AdjustmentMode mode,
    required int qtyChange,
    required String note,
  }) async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(stockRepositoryProvider);
    if (user == null || qtyChange == 0) return false;
    final type = switch (mode) {
      AdjustmentMode.restock => MovementType.restock,
      AdjustmentMode.spoilage => MovementType.spoilage,
      AdjustmentMode.correction => MovementType.adjustment,
    };
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => repo.adjust(
        productId: productId,
        type: type,
        qtyChange: qtyChange,
        note: note,
        by: user,
      ),
    );
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}

final stockAdjustControllerProvider =
    AsyncNotifierProvider.autoDispose<StockAdjustController, void>(
      StockAdjustController.new,
    );

/// Accumulated pages of one product's movement history.
@immutable
class MovementHistoryState {
  const MovementHistoryState({
    required this.items,
    required this.cursor,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<StockMovement> items;
  final Object? cursor;
  final bool hasMore;
  final bool loadingMore;
}

/// Paginated movement history for one product.
class MovementHistoryController extends AsyncNotifier<MovementHistoryState> {
  MovementHistoryController(this.productId);

  final String productId;

  @override
  Future<MovementHistoryState> build() async {
    final page = await ref
        .watch(stockRepositoryProvider)
        .movementsForProduct(productId);
    return MovementHistoryState(
      items: page.items,
      cursor: page.cursor,
      hasMore: page.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    final repo = ref.read(stockRepositoryProvider);
    state = AsyncData(
      MovementHistoryState(
        items: current.items,
        cursor: current.cursor,
        hasMore: current.hasMore,
        loadingMore: true,
      ),
    );
    final result = await AsyncValue.guard(
      () => repo.movementsForProduct(productId, after: current.cursor),
    );
    if (!ref.mounted) return;
    state = switch (result) {
      AsyncData(:final value) => AsyncData(
        MovementHistoryState(
          items: [...current.items, ...value.items],
          cursor: value.cursor,
          hasMore: value.hasMore,
        ),
      ),
      _ => AsyncData(current),
    };
  }
}

final movementHistoryProvider = AsyncNotifierProvider.autoDispose
    .family<MovementHistoryController, MovementHistoryState, String>(
      MovementHistoryController.new,
    );
