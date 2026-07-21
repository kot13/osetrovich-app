import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/promotions/domain/promotion_article.dart';
import 'package:osetrovich/features/promotions/domain/promotion_type.dart';
import 'package:osetrovich/features/promotions/domain/promotions_notifier.dart';
import 'package:osetrovich/features/promotions/domain/selected_type_provider.dart';

void main() {
  test('promotions notifier loads all articles by default', () async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    container.read(promotionsNotifierProvider);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final articles = container.read(promotionsNotifierProvider).valueOrNull;
    expect(articles, isNotNull);
    expect(articles!.length, 11);
    expect(articles.any((a) => a.type == PromotionType.promotion), isTrue);
    expect(articles.any((a) => a.type == PromotionType.news), isTrue);
  });

  test('promotions notifier reloads when type changes', () async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    container.listen(promotionsNotifierProvider, (_, __) {});
    await container.read(promotionsNotifierProvider.future);

    container
        .read(selectedPromotionTypeProvider.notifier)
        .select(PromotionType.news);
    await container.read(promotionsNotifierProvider.notifier).reload();

    final articles = container.read(promotionsNotifierProvider);
    expect(articles.hasValue, isTrue);
    expect(
      articles.requireValue.every((a) => a.type == PromotionType.news),
      isTrue,
    );
  });

  test(
    'promotions notifier returns empty list for type without data',
    () async {
      final mock = _EmptyNewsMockApiClient();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mock)],
      );
      addTearDown(container.dispose);

      container
          .read(selectedPromotionTypeProvider.notifier)
          .select(PromotionType.news);
      container.read(promotionsNotifierProvider);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final articles = container.read(promotionsNotifierProvider).valueOrNull;
      expect(articles, isEmpty);
    },
  );
}

class _EmptyNewsMockApiClient extends MockApiClient {
  @override
  Future<List<PromotionArticleSummary>> getPromotionArticles(
    PromotionType type,
  ) async {
    if (type == PromotionType.news) {
      return [];
    }
    return super.getPromotionArticles(type);
  }
}
