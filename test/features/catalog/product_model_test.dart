import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';

void main() {
  group('ProductSummary.fromJson', () {
    test('parses integer id and promo flags', () {
      final product = ProductSummary.fromJson({
        'id': 1001,
        'name': 'Сёмга',
        'weightLabel': '500 г',
        'priceRub': 300,
        'oldPriceRub': 450,
        'imageUrl': 'https://example.com/1.jpg',
        'categoryIds': [1],
        'sale': true,
        'special': false,
      });

      expect(product.id, 1001);
      expect(product.categoryIds, [1]);
      expect(product.sale, isTrue);
      expect(product.special, isFalse);
      expect(product.oldPriceRub, 450);
    });
  });

  group('ProductDetail.fromJson', () {
    test('parses integer id and promo flags', () {
      final detail = ProductDetail.fromJson({
        'id': 2000,
        'name': 'Икра',
        'weightLabel': '100 г',
        'priceRub': 1200,
        'oldPriceRub': 1500,
        'imageUrls': ['https://example.com/1.jpg'],
        'description': 'Описание',
        'categoryIds': [2],
        'sale': false,
        'special': true,
      });

      expect(detail.id, 2000);
      expect(detail.categoryIds, [2]);
      expect(detail.special, isTrue);
    });

    test('falls back to imageUrl when imageUrls is empty', () {
      final detail = ProductDetail.fromJson({
        'id': 512,
        'name': 'Икра',
        'weightLabel': '0 кг',
        'priceRub': 749,
        'oldPriceRub': 0,
        'imageUrl': 'https://example.com/fallback.jpg',
        'imageUrls': <String>[],
        'description': '',
        'categoryIds': [13],
        'sale': false,
        'special': false,
      });

      expect(detail.imageUrls, ['https://example.com/fallback.jpg']);
    });

    test('allows empty images when API returns no urls', () {
      final detail = ProductDetail.fromJson({
        'id': 512,
        'name': 'Икра',
        'weightLabel': '0 кг',
        'priceRub': 749,
        'oldPriceRub': 0,
        'imageUrl': '',
        'imageUrls': <String>[],
        'description': '',
        'categoryIds': [13],
        'sale': false,
        'special': false,
      });

      expect(detail.imageUrls, isEmpty);
    });
  });
}
