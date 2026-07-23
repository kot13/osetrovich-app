import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/cart/domain/cart_line_item_view.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';

void main() {
  test('fromProduct handles empty imageUrls', () {
    const product = ProductDetail(
      id: 512,
      name: 'Икра',
      weightLabel: '0 кг',
      priceRub: 749,
      oldPriceRub: 0,
      pricePerKgRub: 0,
      imageUrls: [],
      description: '',
      categoryIds: [13],
      sale: false,
      special: false,
      productOfWeek: false,
      pieceProduct: false,
    );

    final line = CartLineItemView.fromProduct(product, 2);

    expect(line.imageUrl, '');
    expect(line.sale, isFalse);
    expect(line.lineTotalRub, 1498);
  });
}
