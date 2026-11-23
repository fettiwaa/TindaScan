import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/utils/formatters.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/features/products/application/product_providers.dart';
import 'package:tindascan/features/stock/application/stock_controllers.dart';
import 'package:tindascan/features/stock/presentation/movement_labels.dart';
import 'package:tindascan/shared/models/stock_movement.dart';

/// Paginated stock movement history for one product (owner).
class MovementHistoryScreen extends ConsumerWidget {
  const MovementHistoryScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(movementHistoryProvider(productId));
    final name = ref.watch(
      productByIdProvider(productId).select((p) => p.value?.name),
    );
    return Scaffold(
      appBar: AppBar(title: Text(name ?? l10n.productHistory)),
      body: AsyncValueView<MovementHistoryState>(
        value: history,
        onRetry: () => ref.invalidate(movementHistoryProvider(productId)),
        isEmpty: (s) => s.items.isEmpty,
        emptyMessage: l10n.stockHistoryEmpty,
        data: (state) => ListView.builder(
          itemCount: state.items.length + 1,
          itemBuilder: (context, index) {
            if (index == state.items.length) {
              if (state.loadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(Gaps.md),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return state.hasMore
                  ? Center(
                      child: TextButton(
                        onPressed: () => ref
                            .read(movementHistoryProvider(productId).notifier)
                            .loadMore(),
                        child: Text(l10n.loadMore),
                      ),
                    )
                  : const SizedBox.shrink();
            }
            return _MovementTile(movement: state.items[index]);
          },
        ),
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final created = movement.createdAt;
    final positive = movement.qtyChange > 0;
    final details = [
      if (created != null) AppFormat.dateTime(context, created),
      if (movement.userName.isNotEmpty) l10n.movementBy(movement.userName),
      if (movement.note.isNotEmpty) movement.note,
    ];
    return ListTile(
      leading: Icon(movement.type.icon),
      title: Text(movement.type.label(l10n)),
      subtitle: Text(details.join('\n')),
      isThreeLine: details.length > 1,
      trailing: Text(
        positive ? '+${movement.qtyChange}' : '${movement.qtyChange}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: positive ? context.tokens.success : scheme.error,
        ),
      ),
    );
  }
}
