import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/cart/domain/delivery_fee.dart';

void main() {
  test('delivery fee is 300 below threshold', () {
    expect(calculateDeliveryFeeRub(1999), 300);
  });

  test('delivery fee is free at threshold', () {
    expect(calculateDeliveryFeeRub(2000), 0);
  });

  test('delivery fee is free above threshold', () {
    expect(calculateDeliveryFeeRub(2500), 0);
  });
}
