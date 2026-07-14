import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/promotions/domain/promotion_type.dart';
import 'package:osetrovich/features/promotions/presentation/widgets/promotion_type_chips.dart';

void main() {
  testWidgets(
    'promotion type chips show three options with accent on selected',
    (tester) async {
      var selected = PromotionType.all;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: PromotionTypeChips(
              selectedType: selected,
              onSelected: (type) => selected = type,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.chipAll), findsOneWidget);
      expect(find.text(AppStrings.chipPromotions), findsOneWidget);
      expect(find.text(AppStrings.chipNews), findsOneWidget);

      final allChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, AppStrings.chipAll),
      );
      expect(allChip.selected, isTrue);
      expect(allChip.selectedColor, AppColors.accent);

      await tester.tap(find.text(AppStrings.chipNews));
      await tester.pumpAndSettle();

      expect(selected, PromotionType.news);
    },
  );
}
