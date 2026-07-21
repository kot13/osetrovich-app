import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/cart/domain/order_totals.dart';
import 'package:osetrovich/features/cart/presentation/widgets/cart_order_summary.dart';

void main() {
  testWidgets('cart order summary shows subtotal delivery and total', (
    tester,
  ) async {
    const totals = OrderTotals(
      itemsSubtotalBeforeDiscountRub: 1500,
      itemsSubtotalRub: 1500,
      loyaltyDiscountRub: 0,
      deliveryFeeRub: 300,
      totalRub: 1800,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: CartOrderSummary(totals: totals)),
      ),
    );

    expect(find.text(AppStrings.cartItemsSubtotal), findsOneWidget);
    expect(find.text(AppStrings.cartDeliveryFee), findsOneWidget);
    expect(find.text(AppStrings.cartTotal), findsOneWidget);
    expect(find.text('1500\u00A0₽'), findsOneWidget);
    expect(find.text('300\u00A0₽'), findsOneWidget);
    expect(find.text('1800\u00A0₽'), findsOneWidget);
    expect(find.text(AppStrings.cartSubtotalAfterDiscount), findsNothing);
  });

  testWidgets('cart order summary shows loyalty discount rows', (tester) async {
    const totals = OrderTotals(
      itemsSubtotalBeforeDiscountRub: 2000,
      itemsSubtotalRub: 1800,
      loyaltyDiscountRub: 200,
      loyaltyDiscountPercent: 10,
      deliveryFeeRub: 300,
      totalRub: 2100,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: CartOrderSummary(totals: totals)),
      ),
    );

    expect(find.text('2000\u00A0₽'), findsOneWidget);
    expect(find.text(AppStrings.cartLoyaltyDiscount(10)), findsOneWidget);
    expect(find.text('−200\u00A0₽'), findsOneWidget);
    expect(find.text(AppStrings.cartSubtotalAfterDiscount), findsOneWidget);
    expect(find.text('1800\u00A0₽'), findsOneWidget);
    expect(find.text('2100\u00A0₽'), findsOneWidget);
  });
}
