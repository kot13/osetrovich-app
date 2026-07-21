import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/cart/domain/cart_display_lines_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_line_item_view.dart';

const _line = CartLineItemView(
  productId: 1000,
  name: 'Сёмга',
  weightLabel: '500 г',
  priceRub: 450,
  imageUrl: '',
  quantity: 1,
  sale: false,
);

const _giftLine = CartLineItemView(
  productId: 501,
  name: 'Икра горбуши',
  weightLabel: '50 г',
  priceRub: 0,
  originalPriceRub: 749,
  imageUrl: 'https://example.com/ikra.jpg',
  quantity: 1,
  sale: false,
  isGift: true,
);

void main() {
  group('buildCartDisplayLines', () {
    test('appends gift when eligible', () {
      final lines = buildCartDisplayLines(
        cartLines: const [_line],
        isAuthenticated: true,
        lemons: 10,
        cartIsEmpty: false,
        giftLine: _giftLine,
      );

      expect(lines, hasLength(2));
      expect(lines.last.isGift, isTrue);
    });

    test('does not append gift when lemons below 10', () {
      final lines = buildCartDisplayLines(
        cartLines: const [_line],
        isAuthenticated: true,
        lemons: 7,
        cartIsEmpty: false,
        giftLine: _giftLine,
      );

      expect(lines, hasLength(1));
      expect(lines.first.isGift, isFalse);
    });

    test('does not append gift for guest or empty cart', () {
      expect(
        buildCartDisplayLines(
          cartLines: const [_line],
          isAuthenticated: false,
          lemons: 10,
          cartIsEmpty: false,
          giftLine: _giftLine,
        ),
        hasLength(1),
      );

      expect(
        buildCartDisplayLines(
          cartLines: const [_line],
          isAuthenticated: true,
          lemons: 10,
          cartIsEmpty: true,
          giftLine: _giftLine,
        ),
        hasLength(1),
      );
    });

    test('does not append gift when gift line is missing', () {
      final lines = buildCartDisplayLines(
        cartLines: const [_line],
        isAuthenticated: true,
        lemons: 10,
        cartIsEmpty: false,
      );

      expect(lines, hasLength(1));
    });
  });
}
