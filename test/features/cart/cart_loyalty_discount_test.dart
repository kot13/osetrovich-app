import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/cart/domain/cart_line_item_view.dart';
import 'package:osetrovich/features/cart/domain/cart_loyalty_discount.dart';
import 'package:osetrovich/features/profile/domain/loyalty_status.dart';

const _regularLine = CartLineItemView(
  productId: 1002,
  name: 'Товар',
  weightLabel: '500 г',
  priceRub: 1000,
  imageUrl: '',
  quantity: 1,
  sale: false,
);

const _saleLine = CartLineItemView(
  productId: 1000,
  name: 'Акционный товар',
  weightLabel: '500 г',
  priceRub: 1000,
  imageUrl: '',
  quantity: 1,
  sale: true,
);

void main() {
  group('isCartLineEligibleForLoyaltyDiscount', () {
    test('non-sale line is always eligible', () {
      expect(
        isCartLineEligibleForLoyaltyDiscount(
          sale: false,
          loyaltyStatus: LoyaltyStatus.premium,
        ),
        isTrue,
      );
    });

    test('sale line excluded for premium status', () {
      expect(
        isCartLineEligibleForLoyaltyDiscount(
          sale: true,
          loyaltyStatus: LoyaltyStatus.premium,
        ),
        isFalse,
      );
    });

    test('sale line included for super vip and vip', () {
      expect(
        isCartLineEligibleForLoyaltyDiscount(
          sale: true,
          loyaltyStatus: LoyaltyStatus.superVip,
        ),
        isTrue,
      );
      expect(
        isCartLineEligibleForLoyaltyDiscount(
          sale: true,
          loyaltyStatus: LoyaltyStatus.vip,
        ),
        isTrue,
      );
    });
  });

  group('calculateOrderTotalsFromLines', () {
    test('applies discount only to eligible lines', () {
      final totals = calculateOrderTotalsFromLines(
        lines: [_regularLine, _saleLine],
        discountPercent: 10,
        loyaltyStatus: LoyaltyStatus.premium,
      );

      expect(totals.itemsSubtotalBeforeDiscountRub, 2000);
      expect(totals.itemsSubtotalRub, 1900);
      expect(totals.loyaltyDiscountRub, 100);
      expect(totals.loyaltyDiscountPercent, 10);
      expect(totals.deliveryFeeRub, 300);
      expect(totals.totalRub, 2200);
    });

    test('applies discount to sale lines for vip', () {
      final totals = calculateOrderTotalsFromLines(
        lines: [_saleLine],
        discountPercent: 10,
        loyaltyStatus: LoyaltyStatus.vip,
      );

      expect(totals.itemsSubtotalBeforeDiscountRub, 1000);
      expect(totals.itemsSubtotalRub, 900);
      expect(totals.loyaltyDiscountRub, 100);
    });

    test('no discount when percent is zero', () {
      final totals = calculateOrderTotalsFromLines(
        lines: [_regularLine, _saleLine],
        discountPercent: 0,
        loyaltyStatus: LoyaltyStatus.premium,
      );

      expect(totals.hasLoyaltyDiscount, isFalse);
      expect(totals.itemsSubtotalRub, 2000);
      expect(totals.loyaltyDiscountRub, 0);
    });
  });
}
