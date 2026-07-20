import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';
import 'package:osetrovich/features/catalog/domain/categories_provider.dart';
import 'package:osetrovich/features/catalog/domain/products_notifier.dart';

void main() {
  test('products notifier loads first page for selected category', () async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    container.read(productsNotifierProvider);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final state = container.read(productsNotifierProvider);
    expect(state.isLoadingInitial, isFalse);
    expect(state.items, isNotEmpty);
    expect(state.categoryId, kAllCategoriesId);
  });

  test('products notifier resets and loads on category change', () async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    container.read(productsNotifierProvider);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    container.read(selectedCategoryIdProvider.notifier).select(kCategoryFish);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final state = container.read(productsNotifierProvider);
    expect(state.categoryId, kCategoryFish);
    expect(
      state.items.every((p) => p.categoryIds.contains(kCategoryFish)),
      isTrue,
    );
  });

  test('products notifier appends next page on loadMore', () async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    container.read(selectedCategoryIdProvider.notifier).select(kCategoryFish);
    container.read(productsNotifierProvider);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    await container.read(productsNotifierProvider.notifier).loadMore();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final state = container.read(productsNotifierProvider);
    expect(state.items.length, 30);
    expect(state.hasMore, isFalse);
  });
}
