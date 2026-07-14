import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/cart/domain/order_totals.dart';

void main() {
  test('order totals below free delivery threshold', () {
    final totals = calculateOrderTotals(1500);

    expect(totals.itemsSubtotalRub, 1500);
    expect(totals.deliveryFeeRub, 300);
    expect(totals.totalRub, 1800);
  });

  test('order totals at free delivery threshold', () {
    final totals = calculateOrderTotals(2000);

    expect(totals.itemsSubtotalRub, 2000);
    expect(totals.deliveryFeeRub, 0);
    expect(totals.totalRub, 2000);
  });
}
