import 'package:flutter/material.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';

class ProductPromoBadges extends StatelessWidget {
  const ProductPromoBadges({
    super.key,
    required this.productOfWeek,
    required this.sale,
    required this.special,
  });

  final bool productOfWeek;
  final bool sale;
  final bool special;

  @override
  Widget build(BuildContext context) {
    if (!productOfWeek && !sale && !special) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (productOfWeek)
          _Badge(
            label: AppStrings.badgeProductOfWeek,
            style: _BadgeStyle.productOfWeek,
          ),
        if (productOfWeek && (sale || special)) const SizedBox(width: 4),
        if (sale) _Badge(label: AppStrings.badgeSale, style: _BadgeStyle.sale),
        if (sale && special) const SizedBox(width: 4),
        if (special)
          _Badge(
            label: AppStrings.badgeSpecialPrice,
            style: _BadgeStyle.special,
          ),
      ],
    );
  }
}

enum _BadgeStyle { productOfWeek, sale, special }

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.style});

  final String label;
  final _BadgeStyle style;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (style) {
      _BadgeStyle.productOfWeek => (AppColors.dark, AppColors.accent),
      _BadgeStyle.sale => (AppColors.accent, AppColors.dark),
      _BadgeStyle.special => (AppColors.primary, Colors.white),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
