import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';
import 'package:osetrovich/core/utils/product_price_display.dart';
import 'package:osetrovich/core/utils/product_weight_parser.dart';

void main() {
  group('parseProductWeightKg', () {
    test('parses grams', () {
      expect(parseProductWeightKg('500 г'), 0.5);
      expect(parseProductWeightKg('300г'), 0.3);
    });

    test('parses kilograms', () {
      expect(parseProductWeightKg('1 кг'), 1.0);
      expect(parseProductWeightKg('0.5 кг'), 0.5);
    });

    test('returns null for piece labels', () {
      expect(parseProductWeightKg('1 шт'), isNull);
    });
  });

  group('shouldMultiplyPriceByWeight', () {
    test('returns true for non-piece product not weighing 1 kg', () {
      expect(
        shouldMultiplyPriceByWeight(
          pieceProduct: false,
          weightLabel: '500 г',
        ),
        isTrue,
      );
    });

    test('returns false for 1 kg weight product', () {
      expect(
        shouldMultiplyPriceByWeight(
          pieceProduct: false,
          weightLabel: '1 кг',
        ),
        isFalse,
      );
    });

    test('returns false for piece product', () {
      expect(
        shouldMultiplyPriceByWeight(
          pieceProduct: true,
          weightLabel: '500 г',
        ),
        isFalse,
      );
    });
  });

  group('productDisplayPriceRub', () {
    test('multiplies per-kg price by weight for weight products', () {
      expect(
        productDisplayPriceRub(
          priceRub: 1500,
          weightLabel: '300 г',
          pieceProduct: false,
        ),
        450,
      );
    });

    test('keeps price for piece product', () {
      expect(
        productDisplayPriceRub(
          priceRub: 510,
          weightLabel: '1 шт',
          pieceProduct: true,
        ),
        510,
      );
    });

    test('keeps price for 1 kg product', () {
      expect(
        productDisplayPriceRub(
          priceRub: 632,
          weightLabel: '1 кг',
          pieceProduct: false,
        ),
        632,
      );
    });
  });

  group('ProductCatalogPriceDisplay', () {
    test('shows price per kg for regular product', () {
      final prices = ProductCatalogPriceDisplay.resolve(
        priceRub: 1500,
        oldPriceRub: 2000,
        pricePerKgRub: 2400,
        weightLabel: '300 г',
        pieceProduct: false,
        special: false,
      );

      expect(prices.buttonPriceRub, 450);
      expect(prices.buttonOldPriceRub, 600);
      expect(prices.secondaryPriceLabel, formatPricePerKgRub(2400));
    });

    test('shows special total instead of price per kg', () {
      final prices = ProductCatalogPriceDisplay.resolve(
        priceRub: 12000,
        oldPriceRub: 15000,
        pricePerKgRub: 12000,
        weightLabel: '100 г',
        pieceProduct: false,
        special: true,
      );

      expect(prices.buttonPriceRub, 1200);
      expect(prices.secondaryPriceLabel, formatPriceRub(1200));
      expect(prices.secondaryPriceLabel, isNot(contains('/кг')));
    });
  });

  group('shouldShowStrikethroughOldPrice', () {
    test('returns true when old price is greater than current', () {
      expect(
        shouldShowStrikethroughOldPrice(oldPriceRub: 600, priceRub: 450),
        isTrue,
      );
    });

    test('returns false when old price equals current', () {
      expect(
        shouldShowStrikethroughOldPrice(oldPriceRub: 300, priceRub: 300),
        isFalse,
      );
    });

    test('returns false when old price is less than current', () {
      expect(
        shouldShowStrikethroughOldPrice(oldPriceRub: 200, priceRub: 300),
        isFalse,
      );
    });

    test('returns false when old price is zero', () {
      expect(
        shouldShowStrikethroughOldPrice(oldPriceRub: 0, priceRub: 300),
        isFalse,
      );
    });
  });

  group('formatPricePerKgRub', () {
    test('appends /кг suffix', () {
      expect(formatPricePerKgRub(2400), '${formatPriceRub(2400)}/кг');
    });
  });
}
