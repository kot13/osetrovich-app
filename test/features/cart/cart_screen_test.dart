import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/cart/presentation/cart_screen.dart';

void main() {
  testWidgets('cart shows empty state and catalog button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CartScreen(),
        ),
      ),
    );

    expect(find.text(AppStrings.cartEmpty), findsOneWidget);
    expect(find.text(AppStrings.goToCatalog), findsOneWidget);
  });
}
