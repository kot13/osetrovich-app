import 'package:osetrovich/features/cart/domain/cart_line_item_view.dart';
import 'package:osetrovich/features/cart/domain/delivery_fee.dart';
import 'package:osetrovich/features/cart/domain/order_totals.dart';
import 'package:osetrovich/features/profile/domain/loyalty_status.dart';

bool loyaltyDiscountIncludesSaleProducts(LoyaltyStatus? status) {
  return status == LoyaltyStatus.superVip || status == LoyaltyStatus.vip;
}

bool isCartLineEligibleForLoyaltyDiscount({
  required bool sale,
  required LoyaltyStatus? loyaltyStatus,
}) {
  if (!sale) {
    return true;
  }
  return loyaltyDiscountIncludesSaleProducts(loyaltyStatus);
}

int applyLoyaltyPercentDiscount(int amountRub, int discountPercent) {
  if (discountPercent <= 0) {
    return amountRub;
  }
  final discountRub = (amountRub * discountPercent / 100).round();
  return amountRub - discountRub;
}

int discountedLineTotalRub({
  required CartLineItemView line,
  required int discountPercent,
  required LoyaltyStatus? loyaltyStatus,
}) {
  final eligible = isCartLineEligibleForLoyaltyDiscount(
    sale: line.sale,
    loyaltyStatus: loyaltyStatus,
  );
  if (!eligible || discountPercent <= 0) {
    return line.lineTotalRub;
  }
  return applyLoyaltyPercentDiscount(line.lineTotalRub, discountPercent);
}

OrderTotals calculateOrderTotalsFromLines({
  required List<CartLineItemView> lines,
  int discountPercent = 0,
  LoyaltyStatus? loyaltyStatus,
}) {
  var itemsSubtotalBeforeDiscountRub = 0;
  var itemsSubtotalRub = 0;

  for (final line in lines) {
    itemsSubtotalBeforeDiscountRub += line.lineTotalRub;
    itemsSubtotalRub += discountedLineTotalRub(
      line: line,
      discountPercent: discountPercent,
      loyaltyStatus: loyaltyStatus,
    );
  }

  final loyaltyDiscountRub = itemsSubtotalBeforeDiscountRub - itemsSubtotalRub;
  final deliveryFeeRub = calculateDeliveryFeeRub(itemsSubtotalRub);

  return OrderTotals(
    itemsSubtotalBeforeDiscountRub: itemsSubtotalBeforeDiscountRub,
    itemsSubtotalRub: itemsSubtotalRub,
    loyaltyDiscountRub: loyaltyDiscountRub,
    loyaltyDiscountPercent: loyaltyDiscountRub > 0 ? discountPercent : null,
    deliveryFeeRub: deliveryFeeRub,
    totalRub: itemsSubtotalRub + deliveryFeeRub,
  );
}
