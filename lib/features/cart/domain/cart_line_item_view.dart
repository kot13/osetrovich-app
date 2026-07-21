import 'package:osetrovich/features/catalog/domain/product.dart';
import 'package:osetrovich/features/profile/domain/lemon_gift_preview.dart';

class CartLineItemView {
  const CartLineItemView({
    required this.productId,
    required this.name,
    required this.weightLabel,
    required this.priceRub,
    required this.imageUrl,
    required this.quantity,
    required this.sale,
    this.isGift = false,
    this.originalPriceRub,
  });

  factory CartLineItemView.fromProduct(ProductDetail product, int quantity) {
    return CartLineItemView(
      productId: product.id,
      name: product.name,
      weightLabel: product.weightLabel,
      priceRub: product.priceRub,
      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
      quantity: quantity,
      sale: product.sale,
    );
  }

  factory CartLineItemView.fromLemonGift(
    LemonGiftPreview gift, {
    required int originalPriceRub,
  }) {
    return CartLineItemView(
      productId: gift.productId,
      name: gift.name,
      weightLabel: gift.weightLabel,
      priceRub: 0,
      originalPriceRub: originalPriceRub,
      imageUrl: gift.imageUrl ?? '',
      quantity: 1,
      sale: false,
      isGift: true,
    );
  }

  final int productId;
  final String name;
  final String weightLabel;
  final int priceRub;
  final String imageUrl;
  final int quantity;
  final bool sale;
  final bool isGift;
  final int? originalPriceRub;

  int get lineTotalRub => priceRub * quantity;
}
