import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/promotions/presentation/promotions_screen.dart';

void main() {
  testWidgets('promotions shows nothing found', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const PromotionsScreen(),
      ),
    );

    expect(find.text(AppStrings.nothingFound), findsOneWidget);
  });
}
