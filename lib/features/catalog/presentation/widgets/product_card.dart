import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/product_promo_badges.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/quantity_price_bar.dart';

/// Зарезервированная высота под название (2 строки) + вес — не отдаётся под фото.
const double _kProductTextBlockHeight = 54;

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final ProductSummary product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(
      cartNotifierProvider.select((cart) => cart[product.id] ?? 0),
    );
    final cart = ref.read(cartNotifierProvider.notifier);

    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.push('/catalog/product/${product.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder:
                                  (_, __) => ColoredBox(
                                    color: AppColors.background,
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: AppColors.dark.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                              errorWidget:
                                  (_, __, ___) => ColoredBox(
                                    color: AppColors.background,
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: AppColors.dark.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: ProductPromoBadges(
                              productOfWeek: product.productOfWeek,
                              sale: product.sale,
                              special: product.special,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: _kProductTextBlockHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.dark,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.weightLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.dark.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: QuantityPriceBar(
                priceRub: product.priceRub,
                quantity: quantity,
                onIncrement: () => cart.increment(product.id),
                onDecrement: () => cart.decrement(product.id),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
