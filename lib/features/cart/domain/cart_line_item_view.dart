import 'package:osetrovich/features/catalog/domain/product.dart';

class CartLineItemView {
  const CartLineItemView({
    required this.productId,
    required this.name,
    required this.weightLabel,
    required this.priceRub,
    required this.imageUrl,
    required this.quantity,
  });

  factory CartLineItemView.fromProduct(ProductDetail product, int quantity) {
    return CartLineItemView(
      productId: product.id,
      name: product.name,
      weightLabel: product.weightLabel,
      priceRub: product.priceRub,
      imageUrl: product.imageUrls.first,
      quantity: quantity,
    );
  }

  final int productId;
  final String name;
  final String weightLabel;
  final int priceRub;
  final String imageUrl;
  final int quantity;

  int get lineTotalRub => priceRub * quantity;
}
