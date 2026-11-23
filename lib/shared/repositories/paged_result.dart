/// One page of a paginated list. [cursor] is opaque to callers; pass it back
/// to fetch the next page.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });

  const PagedResult.empty() : items = const [], cursor = null, hasMore = false;

  final List<T> items;
  final Object? cursor;
  final bool hasMore;
}
