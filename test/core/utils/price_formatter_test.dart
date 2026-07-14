import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';

void main() {
  test('formatPriceRub formats whole rubles with nbsp and sign', () {
    expect(formatPriceRub(300), '300\u00A0₽');
    expect(formatPriceRub(0), '0\u00A0₽');
  });
}
