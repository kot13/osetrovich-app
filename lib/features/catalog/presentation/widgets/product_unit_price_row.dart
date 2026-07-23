import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';
import 'package:osetrovich/core/utils/product_price_display.dart';

/// Цена за единицу: опционально зачёркнутая старая слева от текущей.
class ProductUnitPriceRow extends StatelessWidget {
  const ProductUnitPriceRow({
    super.key,
    required this.priceRub,
    required this.oldPriceRub,
    this.currentPriceStyle,
    this.oldPriceFontSize = 16,
    this.currentPriceFontSize = 18,
    this.priceWeightSuffix,
  });

  final int priceRub;
  final int oldPriceRub;
  final TextStyle? currentPriceStyle;
  final double oldPriceFontSize;
  final double currentPriceFontSize;
  final String? priceWeightSuffix;

  String _formatPrice(int priceRub) {
    final formatted = formatPriceRub(priceRub);
    final suffix = priceWeightSuffix;
    if (suffix == null) {
      return formatted;
    }
    return '$formatted$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final currentStyle =
        currentPriceStyle ??
        TextStyle(
          color: AppColors.primary,
          fontSize: currentPriceFontSize,
          fontWeight: FontWeight.w600,
        );

    if (!shouldShowStrikethroughOldPrice(
      oldPriceRub: oldPriceRub,
      priceRub: priceRub,
    )) {
      return Text(_formatPrice(priceRub), style: currentStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          _formatPrice(oldPriceRub),
          style: TextStyle(
            color: AppColors.dark.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
            fontSize: oldPriceFontSize,
            decoration: TextDecoration.lineThrough,
            decorationColor: AppColors.dark.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 8),
        Text(_formatPrice(priceRub), style: currentStyle),
      ],
    );
  }
}
