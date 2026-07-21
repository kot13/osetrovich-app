/// Результат парсинга `osetrovich://` URL.
class DeepLinkTarget {
  const DeepLinkTarget({
    required this.path,
    this.categoryId,
    this.isFallback = false,
  });

  static const fallback = DeepLinkTarget(path: '/home', isFallback: true);

  final String path;
  final int? categoryId;
  final bool isFallback;
}
