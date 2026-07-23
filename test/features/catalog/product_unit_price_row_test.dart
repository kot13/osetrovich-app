import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/product_unit_price_row.dart';

void main() {
  testWidgets('shows strikethrough old price left of current', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ProductUnitPriceRow(priceRub: 450, oldPriceRub: 600),
        ),
      ),
    );
    await tester.pump();

    final oldPriceFinder = find.text(formatPriceRub(600));
    expect(oldPriceFinder, findsOneWidget);
    expect(
      tester.widget<Text>(oldPriceFinder).style?.decoration,
      TextDecoration.lineThrough,
    );
    expect(find.text(formatPriceRub(450)), findsOneWidget);
  });

  testWidgets('shows only current price when no discount', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ProductUnitPriceRow(priceRub: 300, oldPriceRub: 300),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(formatPriceRub(300)), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.style?.decoration == TextDecoration.lineThrough,
      ),
      findsNothing,
    );
  });

  testWidgets('shows price with weight suffix', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ProductUnitPriceRow(
            priceRub: 2178,
            oldPriceRub: 2400,
            priceWeightSuffix: ' за 2 кг',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(formatPriceForWeightLabel(2178, '2 кг')),
      findsOneWidget,
    );
    expect(
      find.text(formatPriceForWeightLabel(2400, '2 кг')),
      findsOneWidget,
    );
  });

  testWidgets('uses primary color for current price', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: ProductUnitPriceRow(priceRub: 450, oldPriceRub: 600),
        ),
      ),
    );
    await tester.pump();

    final currentPrice = tester.widget<Text>(find.text(formatPriceRub(450)));
    expect(currentPrice.style?.color, AppColors.primary);
  });
}
