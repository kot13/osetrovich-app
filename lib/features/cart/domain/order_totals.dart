import 'package:osetrovich/features/cart/domain/delivery_fee.dart';

class OrderTotals {
  const OrderTotals({
    required this.itemsSubtotalRub,
    required this.deliveryFeeRub,
    required this.totalRub,
  });

  final int itemsSubtotalRub;
  final int deliveryFeeRub;
  final int totalRub;
}

OrderTotals calculateOrderTotals(int itemsSubtotalRub) {
  final deliveryFeeRub = calculateDeliveryFeeRub(itemsSubtotalRub);
  return OrderTotals(
    itemsSubtotalRub: itemsSubtotalRub,
    deliveryFeeRub: deliveryFeeRub,
    totalRub: itemsSubtotalRub + deliveryFeeRub,
  );
}
