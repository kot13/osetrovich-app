import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';

void main() {
  group('MockApiClient products', () {
    test('getProductById returns multi-image product', () async {
      final client = MockApiClient();
      final detail = await client.getProductById('p-fish-0');

      expect(detail.imageUrls.length, 3);
      expect(detail.description, isNotEmpty);
    });

    test('getProductById throws for unknown id', () async {
      final client = MockApiClient();

      expect(client.getProductById('unknown-id'), throwsA(isA<ApiException>()));
    });

    test('getProducts paginates fish category', () async {
      final client = MockApiClient();

      final first = await client.getProducts(
        categoryId: 'fish',
        offset: 0,
        limit: 20,
      );
      final second = await client.getProducts(
        categoryId: 'fish',
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
        categoryId: 'semi_finished',
        offset: 0,
        limit: 20,
      );

      expect(page.items, isEmpty);
      expect(page.total, 0);
      expect(page.hasMore, isFalse);
    });
  });
}
