import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';
import 'package:osetrovich/features/cart/domain/cart_line_item_view.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/quantity_price_bar.dart';

class CartLineTile extends ConsumerWidget {
  const CartLineTile({super.key, required this.line});

  final CartLineItemView line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (line.isGift) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CartLineImage(imageUrl: line.imageUrl, showGiftBadge: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.name,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      line.weightLabel,
                      style: const TextStyle(color: AppColors.dark),
                    ),
                    const SizedBox(height: 4),
                    _GiftPriceRow(originalPriceRub: line.originalPriceRub),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final quantity = ref.watch(cartNotifierProvider)[line.productId] ?? 0;
    if (quantity == 0) {
      return const SizedBox.shrink();
    }

    final cartNotifier = ref.read(cartNotifierProvider.notifier);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CartLineImage(imageUrl: line.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.name,
                        style: const TextStyle(
                          color: AppColors.dark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        line.weightLabel,
                        style: const TextStyle(color: AppColors.dark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatPriceRub(line.priceRub * quantity),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            QuantityPriceBar(
              priceRub: line.priceRub,
              quantity: quantity,
              onIncrement: () => cartNotifier.increment(line.productId),
              onDecrement: () => cartNotifier.decrement(line.productId),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftPriceRow extends StatelessWidget {
  const _GiftPriceRow({required this.originalPriceRub});

  final int? originalPriceRub;

  @override
  Widget build(BuildContext context) {
    final showOriginalPrice =
        originalPriceRub != null && originalPriceRub! > 0;

    return Row(
      children: [
        if (showOriginalPrice) ...[
          Text(
            formatPriceRub(originalPriceRub!),
            style: TextStyle(
              color: AppColors.dark.withValues(alpha: 0.5),
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          formatPriceRub(0),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CartLineImage extends StatelessWidget {
  const _CartLineImage({
    required this.imageUrl,
    this.showGiftBadge = false,
  });

  final String imageUrl;
  final bool showGiftBadge;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 72,
        height: 72,
        child:
            imageUrl.isEmpty
                ? const ColoredBox(
                  color: AppColors.background,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.dark,
                  ),
                )
                : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder:
                      (_, __) => const ColoredBox(color: AppColors.background),
                  errorWidget:
                      (_, __, ___) => const ColoredBox(
                        color: AppColors.background,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.dark,
                        ),
                      ),
                ),
      ),
    );

    if (!showGiftBadge) {
      return image;
    }

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          image,
          Positioned(
            right: -4,
            top: -4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dark.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Icons.card_giftcard,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
