import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/features/promotions/domain/promotion_type.dart';

class PromotionTypeChips extends StatelessWidget {
  const PromotionTypeChips({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  final PromotionType selectedType;
  final ValueChanged<PromotionType> onSelected;

  static const _types = [
    PromotionType.all,
    PromotionType.promotion,
    PromotionType.news,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = _types[index];
          final selected = type == selectedType;
          return FilterChip(
            label: Text(type.chipLabel),
            selected: selected,
            onSelected: (_) => onSelected(type),
            selectedColor: AppColors.accent,
            checkmarkColor: AppColors.dark,
          );
        },
      ),
    );
  }
}
