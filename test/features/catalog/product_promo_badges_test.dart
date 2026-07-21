import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/product_promo_badges.dart';

void main() {
  Widget buildBadges({required bool sale, required bool special}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: ProductPromoBadges(sale: sale, special: special)),
    );
  }

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

  testWidgets('shows both badges', (tester) async {
    await tester.pumpWidget(buildBadges(sale: true, special: true));
    await tester.pump();

    expect(find.text(AppStrings.badgeSale), findsOneWidget);
    expect(find.text(AppStrings.badgeSpecialPrice), findsOneWidget);
  });

  testWidgets('shows no badges when flags are false', (tester) async {
    await tester.pumpWidget(buildBadges(sale: false, special: false));
    await tester.pump();

    expect(find.text(AppStrings.badgeSale), findsNothing);
    expect(find.text(AppStrings.badgeSpecialPrice), findsNothing);
  });
}
