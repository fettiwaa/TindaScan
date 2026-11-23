import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:tindascan/core/constants/app_constants.dart';
import 'package:tindascan/core/errors/failure_messages.dart';
import 'package:tindascan/core/l10n/l10n.dart';
import 'package:tindascan/core/router/app_routes.dart';
import 'package:tindascan/core/theme/app_tokens.dart';
import 'package:tindascan/core/widgets/motion.dart';
import 'package:tindascan/core/widgets/state_views.dart';
import 'package:tindascan/features/auth/application/session_providers.dart';
import 'package:tindascan/features/products/application/product_providers.dart';
import 'package:tindascan/features/products/domain/product_category.dart';
import 'package:tindascan/features/products/presentation/product_detail_screen.dart';
import 'package:tindascan/features/products/presentation/product_labels.dart';
import 'package:tindascan/features/products/presentation/product_tile.dart';
import 'package:tindascan/features/scanner/presentation/barcode_lookup.dart';
import 'package:tindascan/shared/models/product.dart';

/// Product catalog. Owners manage products; staff use it as a read-only
/// price/stock lookup. Phones: list → detail page. Tablets: two panes.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String? _selectedId;

  void _open(Product product, {required bool twoPane}) {
    if (twoPane) {
      setState(() => _selectedId = product.id);
    } else {
      context.push(AppRoutes.productDetail(product.id));
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final twoPane = constraints.maxWidth >= Breakpoints.medium;
      final list = _ProductListPane(
        selectedId: twoPane ? _selectedId : null,
        onOpen: (p) => _open(p, twoPane: twoPane),
      );
      if (!twoPane) return list;
      final selected = _selectedId;
      return Row(
        children: [
          SizedBox(width: AppSizes.listPaneWidth, child: list),
          const VerticalDivider(width: 1),
          Expanded(
            child: Scaffold(
              body: AnimatedSwitcher(
                duration: context.motion.normal,
                child: selected == null
                    ? EmptyState(
                        key: const ValueKey('none'),
                        message: context.l10n.productsSelectHint,
                        icon: Symbols.inventory_2_rounded,
                      )
                    : ProductDetailView(
                        key: ValueKey(selected),
                        productId: selected,
                        embedded: true,
                      ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ProductListPane extends ConsumerStatefulWidget {
  const _ProductListPane({required this.selectedId, required this.onOpen});

  final String? selectedId;
  final ValueChanged<Product> onOpen;

  @override
  ConsumerState<_ProductListPane> createState() => _ProductListPaneState();
}

class _ProductListPaneState extends ConsumerState<_ProductListPane> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  /// Start loading the next page this far before the end of the list.
  static const double _loadMoreExtent = 400;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < _loadMoreExtent) {
      unawaited(ref.read(productListProvider.notifier).loadMore());
    }
  }

  /// Debounced so typing does not fire a query per keystroke.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () {
      final notifier = ref.read(productQueryProvider.notifier);
      notifier.update(ref.read(productQueryProvider).copyWith(search: value));
    });
  }

  Future<void> _scan() async {
    final code = await context.push<String>(AppRoutes.scan);
    if (code == null || !mounted) return;
    final product = await lookupBarcode(context, ref, code);
    if (product != null && mounted) widget.onOpen(product);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isOwner = ref.watch(
      currentUserProvider.select((u) => u?.isOwner ?? false),
    );
    final query = ref.watch(productQueryProvider);
    final queryNotifier = ref.read(productQueryProvider.notifier);
    final list = ref.watch(productListProvider);

    final chips = <Widget>[
      FilterChip(
        label: Text(l10n.productsLowStockFilter),
        selected: query.lowStockOnly,
        onSelected: (v) =>
            queryNotifier.update(query.copyWith(lowStockOnly: v)),
      ),
      if (isOwner)
        FilterChip(
          label: Text(l10n.productsArchivedFilter),
          selected: query.archived,
          onSelected: (v) => queryNotifier.update(query.copyWith(archived: v)),
        ),
      ChoiceChip(
        label: Text(l10n.productsAllCategories),
        selected: query.category == null,
        onSelected: (_) =>
            queryNotifier.update(query.copyWith(clearCategory: true)),
      ),
      for (final category in ProductCategory.values)
        ChoiceChip(
          avatar: CircleAvatar(
            backgroundColor: categoryColor(
              category,
              Theme.of(context).brightness,
            ),
          ),
          label: Text(category.label(l10n)),
          selected: query.category == category,
          onSelected: (_) =>
              queryNotifier.update(query.copyWith(category: category)),
        ),
    ];

    return Scaffold(
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.productNew),
              icon: const Icon(Symbols.add_rounded),
              label: Text(l10n.productAdd),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(productListProvider.future),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: Text(l10n.productsTitle),
              actions: [
                IconButton(
                  tooltip: l10n.productScanBarcode,
                  icon: const Icon(Symbols.barcode_scanner_rounded),
                  onPressed: _scan,
                ),
              ],
            ),
            // Search + filters hide on scroll down and come back on scroll up.
            SliverAppBar(
              primary: false,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              toolbarHeight: 72,
              titleSpacing: Gaps.md,
              title: TextField(
                key: const Key('product-search'),
                controller: _search,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.productsSearchHint,
                  prefixIcon: const Icon(Symbols.search_rounded),
                  suffixIcon: query.search.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.clear,
                          icon: const Icon(Symbols.close_rounded),
                          onPressed: () {
                            _search.clear();
                            _debounce?.cancel();
                            queryNotifier.update(query.copyWith(search: ''));
                          },
                        ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(
                  AppSizes.minTapTarget + Gaps.sm,
                ),
                child: SizedBox(
                  height: AppSizes.minTapTarget + Gaps.sm,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Gaps.md),
                    itemCount: chips.length,
                    separatorBuilder: (_, _) => const SizedBox(width: Gaps.sm),
                    itemBuilder: (_, i) => Center(child: chips[i]),
                  ),
                ),
              ),
            ),
            ...switch (list) {
              AsyncData(:final value) when value.items.isEmpty => [
                SliverFillRemaining(
                  child: EmptyState(
                    message: l10n.productsEmpty,
                    icon: Symbols.inventory_2_rounded,
                    actionLabel: isOwner ? l10n.productAdd : null,
                    onAction: isOwner
                        ? () => context.push(AppRoutes.productNew)
                        : null,
                  ),
                ),
              ],
              AsyncData(:final value) => [
                SliverList.builder(
                  itemCount: value.items.length,
                  itemBuilder: (context, index) {
                    final product = value.items[index];
                    return ProductTile(
                      product: product,
                      selected: product.id == widget.selectedId,
                      hero: widget.selectedId == null,
                      onTap: () => widget.onOpen(product),
                    ).staggerIn(context, index);
                  },
                ),
                SliverToBoxAdapter(child: _ListFooter(state: value)),
              ],
              AsyncError(:final error) => [
                SliverFillRemaining(
                  child: ErrorState(
                    error: error,
                    onRetry: () => ref.invalidate(productListProvider),
                  ),
                ),
              ],
              _ => [
                SliverList.builder(
                  itemCount: 8,
                  itemBuilder: (_, _) => const Skeletonizer(
                    child: ListTile(
                      leading: CircleAvatar(),
                      title: Text('Placeholder product name'),
                      subtitle: Text('₱00.00'),
                    ),
                  ),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }
}

class _ListFooter extends ConsumerWidget {
  const _ListFooter({required this.state});

  final ProductListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final error = state.loadMoreError;
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(Gaps.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return ListTile(
        title: Text(error.toUserMessage(l10n)),
        trailing: TextButton(
          onPressed: () => ref.read(productListProvider.notifier).loadMore(),
          child: Text(l10n.retry),
        ),
      );
    }
    if (state.hasMore) {
      return Center(
        child: TextButton(
          onPressed: () => ref.read(productListProvider.notifier).loadMore(),
          child: Text(l10n.loadMore),
        ),
      );
    }
    // Leave room so the FAB never covers the last row.
    return const SizedBox(height: AppSizes.primaryButtonHeight * 1.8);
  }
}
