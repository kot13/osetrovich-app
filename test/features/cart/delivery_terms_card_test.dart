import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/cart/presentation/widgets/delivery_terms_card.dart';

void main() {
  testWidgets('delivery terms card shows FR-005 text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: DeliveryTermsCard()),
      ),
    );

    expect(find.textContaining('После формирования заказа'), findsOneWidget);
    expect(find.textContaining('2000 руб.'), findsWidgets);
    expect(find.textContaining('300 руб.'), findsOneWidget);
    expect(find.text(AppStrings.cartDeliveryTerms), findsOneWidget);
  });
}
