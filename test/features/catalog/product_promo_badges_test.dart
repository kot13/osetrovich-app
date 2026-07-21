import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/product_promo_badges.dart';

void main() {
  Widget buildBadges({
    bool productOfWeek = false,
    required bool sale,
    required bool special,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: ProductPromoBadges(
          productOfWeek: productOfWeek,
          sale: sale,
          special: special,
        ),
      ),
    );
  }

  testWidgets('shows product of week badge only', (tester) async {
    await tester.pumpWidget(buildBadges(productOfWeek: true, sale: false, special: false));
    await tester.pump();

    expect(find.text(AppStrings.badgeProductOfWeek), findsOneWidget);
    expect(find.text(AppStrings.badgeSale), findsNothing);
    expect(find.text(AppStrings.badgeSpecialPrice), findsNothing);
  });

  testWidgets('shows sale badge only', (tester) async {
    await tester.pumpWidget(buildBadges(sale: true, special: false));
    await tester.pump();

    expect(find.text(AppStrings.badgeSale), findsOneWidget);
    expect(find.text(AppStrings.badgeSpecialPrice), findsNothing);
  });

  testWidgets('shows special badge only', (tester) async {
    await tester.pumpWidget(buildBadges(sale: false, special: true));
    await tester.pump();

    expect(find.text(AppStrings.badgeSale), findsNothing);
    expect(find.text(AppStrings.badgeSpecialPrice), findsOneWidget);
  });

  testWidgets('shows all badges in order', (tester) async {
    await tester.pumpWidget(buildBadges(productOfWeek: true, sale: true, special: true));
    await tester.pump();

    expect(find.text(AppStrings.badgeProductOfWeek), findsOneWidget);
    expect(find.text(AppStrings.badgeSale), findsOneWidget);
    expect(find.text(AppStrings.badgeSpecialPrice), findsOneWidget);

    final weekBadge = tester.widget<Text>(find.text(AppStrings.badgeProductOfWeek));
    expect(weekBadge.style?.color, AppColors.accent);
  });

  testWidgets('shows no badges when flags are false', (tester) async {
    await tester.pumpWidget(buildBadges(sale: false, special: false));
    await tester.pump();

    expect(find.text(AppStrings.badgeSale), findsNothing);
    expect(find.text(AppStrings.badgeSpecialPrice), findsNothing);
    expect(find.text(AppStrings.badgeProductOfWeek), findsNothing);
  });
}
