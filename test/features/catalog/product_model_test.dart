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
        'pricePerKgRub': 2400,
        'imageUrl': 'https://example.com/1.jpg',
        'categoryIds': [1],
        'sale': true,
        'special': false,
        'productOfWeek': true,
        'pieceProduct': false,
      });

      expect(product.id, 1001);
      expect(product.categoryIds, [1]);
      expect(product.sale, isTrue);
      expect(product.special, isFalse);
      expect(product.productOfWeek, isTrue);
      expect(product.oldPriceRub, 450);
      expect(product.pricePerKgRub, 2400);
      expect(product.pieceProduct, isFalse);
    });

    test('parses pieceProduct true', () {
      final product = ProductSummary.fromJson({
        'id': 1002,
        'name': 'Консервы',
        'weightLabel': '1 шт',
        'priceRub': 510,
        'oldPriceRub': 510,
        'pricePerKgRub': 0,
        'imageUrl': 'https://example.com/2.jpg',
        'categoryIds': [1],
        'sale': false,
        'special': false,
        'productOfWeek': false,
        'pieceProduct': true,
      });

      expect(product.pieceProduct, isTrue);
    });

    test('throws when productOfWeek missing', () {
      expect(
        () => ProductSummary.fromJson({
          'id': 1,
          'name': 'x',
          'weightLabel': '1 кг',
          'priceRub': 1,
          'oldPriceRub': 1,
          'pricePerKgRub': 0,
          'imageUrl': 'https://example.com/1.jpg',
          'categoryIds': [1],
          'sale': false,
          'special': false,
        }),
        throwsA(isA<TypeError>()),
      );
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
        'pricePerKgRub': 12000,
        'imageUrls': ['https://example.com/1.jpg'],
        'description': 'Описание',
        'categoryIds': [2],
        'sale': false,
        'special': true,
        'productOfWeek': false,
        'pieceProduct': false,
      });

      expect(detail.id, 2000);
      expect(detail.categoryIds, [2]);
      expect(detail.special, isTrue);
      expect(detail.pricePerKgRub, 12000);
      expect(detail.pieceProduct, isFalse);
    });

    test('falls back to imageUrl when imageUrls is empty', () {
      final detail = ProductDetail.fromJson({
        'id': 512,
        'name': 'Икра',
        'weightLabel': '0 кг',
        'priceRub': 749,
        'oldPriceRub': 0,
        'pricePerKgRub': 0,
        'imageUrl': 'https://example.com/fallback.jpg',
        'imageUrls': <String>[],
        'description': '',
        'categoryIds': [13],
        'sale': false,
        'special': false,
        'productOfWeek': false,
        'pieceProduct': false,
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
        'pricePerKgRub': 0,
        'imageUrl': '',
        'imageUrls': <String>[],
        'description': '',
        'categoryIds': [13],
        'sale': false,
        'special': false,
        'productOfWeek': false,
        'pieceProduct': false,
      });

      expect(detail.imageUrls, isEmpty);
    });
  });
}
