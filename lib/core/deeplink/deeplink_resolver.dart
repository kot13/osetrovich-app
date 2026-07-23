import 'package:osetrovich/core/deeplink/deeplink_target.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';

/// Парсинг `osetrovich://` → [DeepLinkTarget] (контракт deeplink-schema.yaml).
class DeepLinkResolver {
  const DeepLinkResolver();

  DeepLinkTarget resolve(String url) {
    final trimmed = url.trim();
    if (!trimmed.startsWith('osetrovich://')) {
      return DeepLinkTarget.fallback;
    }

    final Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } on Object {
      return DeepLinkTarget.fallback;
    }

    if (uri.scheme != 'osetrovich') {
      return DeepLinkTarget.fallback;
    }

    final host = uri.host;
    final segments =
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList();

    return switch (host) {
      'home' =>
        segments.isEmpty
            ? const DeepLinkTarget(path: '/home')
            : DeepLinkTarget.fallback,
      'catalog' => _resolveCatalog(segments),
      'promotions' => _resolvePromotions(segments),
      'profile' =>
        segments.isEmpty
            ? const DeepLinkTarget(path: '/profile')
            : DeepLinkTarget.fallback,
      'notifications' => _resolveNotifications(segments),
      _ => DeepLinkTarget.fallback,
    };
  }

  DeepLinkTarget _resolveCatalog(List<String> segments) {
    if (segments.isEmpty) {
      return const DeepLinkTarget(
        path: '/catalog',
        categoryId: kAllCategoriesId,
      );
    }

    if (segments.length == 2 && segments[0] == 'category') {
      final id = int.tryParse(segments[1]);
      if (id == null) {
        return DeepLinkTarget.fallback;
      }
      return DeepLinkTarget(path: '/catalog', categoryId: id);
    }

    if (segments.length == 2 && segments[0] == 'product') {
      final id = int.tryParse(segments[1]);
      if (id == null) {
        return DeepLinkTarget.fallback;
      }
      return DeepLinkTarget(path: '/catalog/product/$id');
    }

    return DeepLinkTarget.fallback;
  }

  DeepLinkTarget _resolvePromotions(List<String> segments) {
    if (segments.isEmpty) {
      return const DeepLinkTarget(path: '/promotions');
    }

    if (segments.length == 2 && segments[0] == 'articles') {
      return DeepLinkTarget(path: '/promotions/article/${segments[1]}');
    }

    return DeepLinkTarget.fallback;
  }

  DeepLinkTarget _resolveNotifications(List<String> segments) {
    // In-app bell from other tabs uses branch-local routes; deeplinks stay on /home.
    if (segments.isEmpty) {
      return const DeepLinkTarget(path: '/home/notifications');
    }

    if (segments.length == 1) {
      return DeepLinkTarget(path: '/home/notifications/${segments[0]}');
    }

    return DeepLinkTarget.fallback;
  }
}
