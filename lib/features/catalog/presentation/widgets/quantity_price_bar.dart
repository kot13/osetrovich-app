import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';

enum QuantityPriceBarMode { compact, detail }

/// Высота compact-кнопок (− / +) и кнопки «цена +» — одинаковая, чтобы карточка не прыгала.
const double kCompactBarHeight = 26;

/// Высота кнопок на экране товара (удобнее нажимать).
const double kDetailBarHeight = 44;

class QuantityPriceBar extends StatelessWidget {
  const QuantityPriceBar({
    super.key,
    required this.priceRub,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.mode = QuantityPriceBarMode.compact,
  });

  final int priceRub;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final QuantityPriceBarMode mode;

  bool get _isCompact => mode == QuantityPriceBarMode.compact;

  @override
  Widget build(BuildContext context) {
    final priceLabel = formatPriceRub(priceRub);

    if (quantity == 0) {
      return _BarButton(
        label: '$priceLabel +',
        onTap: onIncrement,
        compact: _isCompact,
      );
    }

    final quantityLabel = '$quantity × $priceLabel';

    if (!_isCompact) {
      return SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            _IconButton(icon: Icons.remove, onTap: onDecrement),
            Expanded(
              child: Center(
                child: Text(
                  quantityLabel,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _IconButton(icon: Icons.add, onTap: onIncrement),
          ],
        ),
      );
    }

    return Row(
      children: [
        _IconButton(icon: Icons.remove, onTap: onDecrement, compact: true),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              quantityLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.dark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        _IconButton(icon: Icons.add, onTap: onIncrement, compact: true),
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    required this.onTap,
    this.compact = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 6.0 : 8.0;
    final height = compact ? kCompactBarHeight : kDetailBarHeight;

    return SizedBox(
      height: height,
      child: Material(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.dark,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12 : 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = compact ? 6.0 : 8.0;
    final iconSize = compact ? 18.0 : 24.0;
    final size = compact ? kCompactBarHeight : kDetailBarHeight;

    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          height: size,
          width: size,
          child: Center(
            child: Icon(icon, size: iconSize, color: AppColors.dark),
          ),
        ),
      ),
    );
  }
}
