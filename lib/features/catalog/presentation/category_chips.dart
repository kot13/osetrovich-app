import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CatalogCategory> categories;
  final int selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final sorted = List<CatalogCategory>.from(categories)
      ..sort((a, b) {
        if (a.id == kAllCategoriesId) {
          return -1;
        }
        if (b.id == kAllCategoriesId) {
          return 1;
        }
        return a.sortOrder.compareTo(b.sortOrder);
      });

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = sorted[index];
          final selected = category.id == selectedId;
          return FilterChip(
            label: Text(category.name),
            selected: selected,
            onSelected: (_) => onSelected(category.id),
            selectedColor: AppColors.accent,
            checkmarkColor: AppColors.dark,
          );
        },
      ),
    );
  }
}
