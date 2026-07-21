import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/deeplink/deeplink_resolver.dart';
import 'package:osetrovich/core/deeplink/deeplink_target.dart';
import 'package:osetrovich/features/catalog/domain/categories_provider.dart';
import 'package:osetrovich/features/catalog/domain/products_notifier.dart';

typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);

/// Навигация по [DeepLinkTarget] с побочными эффектами (фильтр категории).
class DeepLinkNavigation {
  const DeepLinkNavigation._();

  static void navigate(
    GoRouter router,
    ProviderReader read,
    DeepLinkTarget target,
  ) {
    if (target.categoryId != null) {
      final categoryId = target.categoryId!;
      read(selectedCategoryIdProvider.notifier).select(categoryId);
      read(productsNotifierProvider.notifier).selectCategory(categoryId);
    }

    router.go(target.path);
  }

  static void navigateFromUrl(
    GoRouter router,
    ProviderReader read,
    String url, {
    DeepLinkResolver resolver = const DeepLinkResolver(),
  }) {
    navigate(router, read, resolver.resolve(url));
  }
}
