import 'package:osetrovich/features/cart/domain/delivery_fee.dart';

class OrderTotals {
  const OrderTotals({
    required this.itemsSubtotalBeforeDiscountRub,
    required this.itemsSubtotalRub,
    required this.loyaltyDiscountRub,
    required this.deliveryFeeRub,
    required this.totalRub,
    this.loyaltyDiscountPercent,
  });

  final int itemsSubtotalBeforeDiscountRub;
  final int itemsSubtotalRub;
  final int loyaltyDiscountRub;
  final int? loyaltyDiscountPercent;
  final int deliveryFeeRub;
  final int totalRub;

  bool get hasLoyaltyDiscount => loyaltyDiscountRub > 0;
}

OrderTotals calculateOrderTotals(int itemsSubtotalRub) {
  final deliveryFeeRub = calculateDeliveryFeeRub(itemsSubtotalRub);
  return OrderTotals(
    itemsSubtotalBeforeDiscountRub: itemsSubtotalRub,
    itemsSubtotalRub: itemsSubtotalRub,
    loyaltyDiscountRub: 0,
    deliveryFeeRub: deliveryFeeRub,
    totalRub: itemsSubtotalRub + deliveryFeeRub,
  );
}
