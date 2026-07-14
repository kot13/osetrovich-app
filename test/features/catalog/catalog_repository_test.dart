import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/catalog/data/catalog_repository.dart';

void main() {
  late CatalogRepository repository;

  setUp(() {
    repository = CatalogRepository(MockApiClient());
  });

  test('getProducts returns first page for fish category', () async {
    final page = await repository.getProducts(
      categoryId: 'fish',
      offset: 0,
      limit: 20,
    );

    expect(page.items.length, 20);
    expect(page.total, 30);
    expect(page.hasMore, isTrue);
    expect(page.items.first.categoryIds, contains('fish'));
  });

  test('getProducts returns second page for fish category', () async {
    final page = await repository.getProducts(
      categoryId: 'fish',
      offset: 20,
      limit: 20,
    );

    expect(page.items.length, 10);
    expect(page.hasMore, isFalse);
  });

  test('getProductById returns detail for known product', () async {
    final detail = await repository.getProductById('p-fish-0');

    expect(detail.id, 'p-fish-0');
    expect(detail.imageUrls.length, greaterThan(1));
    expect(detail.description, isNotEmpty);
  });
}
