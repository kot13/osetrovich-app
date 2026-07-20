import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/catalog/data/catalog_repository.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';

void main() {
  late CatalogRepository repository;

  setUp(() {
    repository = CatalogRepository(MockApiClient());
  });

  test('getProducts returns first page for fish category', () async {
    final page = await repository.getProducts(
      categoryId: kCategoryFish,
      offset: 0,
      limit: 20,
    );

    expect(page.items.length, 20);
    expect(page.total, 30);
    expect(page.hasMore, isTrue);
    expect(page.items.first.categoryIds, contains(kCategoryFish));
  });

  test('getProducts returns second page for fish category', () async {
    final page = await repository.getProducts(
      categoryId: kCategoryFish,
      offset: 20,
      limit: 20,
    );

    expect(page.items.length, 10);
    expect(page.hasMore, isFalse);
  });

  test('getProductById returns detail for known product', () async {
    final detail = await repository.getProductById(1000);

    expect(detail.id, 1000);
    expect(detail.imageUrls.length, greaterThan(1));
    expect(detail.description, isNotEmpty);
    expect(detail.sale, isTrue);
  });
}
