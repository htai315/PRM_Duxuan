class PaginationConfig {
  static const int defaultPageSize = 20;
  static const int prefetchThreshold = 5;
}

class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final bool hasMore;

  PagedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.hasMore,
  });
}
