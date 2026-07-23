import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';

void main() {
  group('MockApiClient products', () {
    test('getProductById returns multi-image product', () async {
      final client = MockApiClient();
      final detail = await client.getProductById(1000);

      expect(detail.imageUrls.length, 3);
      expect(detail.description, isNotEmpty);
      expect(detail.sale, isTrue);
      expect(detail.pricePerKgRub, 2400);
      expect(detail.pieceProduct, isFalse);
    });

    test('getProductById returns piece product fields', () async {
      final client = MockApiClient();
      final detail = await client.getProductById(1002);

      expect(detail.pieceProduct, isTrue);
      expect(detail.pricePerKgRub, 1800);
    });

    test('getProductById throws for unknown id', () async {
      final client = MockApiClient();

      expect(client.getProductById(999999), throwsA(isA<ApiException>()));
    });

    test('getProducts paginates fish category', () async {
      final client = MockApiClient();

      final first = await client.getProducts(
        categoryId: kCategoryFish,
        offset: 0,
        limit: 20,
      );
      final second = await client.getProducts(
        categoryId: kCategoryFish,
        offset: 20,
        limit: 20,
      );

      expect(first.items.length, 20);
      expect(first.hasMore, isTrue);
      expect(second.items.length, 10);
      expect(second.hasMore, isFalse);
    });

    test('semi_finished category has no products', () async {
      final client = MockApiClient();
      final page = await client.getProducts(
        categoryId: kCategorySemiFinished,
        offset: 0,
        limit: 20,
      );

      expect(page.items, isEmpty);
      expect(page.total, 0);
      expect(page.hasMore, isFalse);
    });
  });
}
