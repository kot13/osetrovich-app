import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/quantity_price_bar.dart';

void main() {
  testWidgets('shows strikethrough old price when quantity is zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: QuantityPriceBar(
            priceRub: 450,
            oldPriceRub: 600,
            quantity: 0,
            onIncrement: () {},
            onDecrement: () {},
          ),
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
    expect(find.text('${formatPriceRub(450)} +'), findsOneWidget);
  });

  testWidgets('hides old price when equal to current', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: QuantityPriceBar(
            priceRub: 300,
            oldPriceRub: 300,
            quantity: 0,
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('${formatPriceRub(300)} +'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.style?.decoration == TextDecoration.lineThrough,
      ),
      findsNothing,
    );
  });

  testWidgets('hides old price when quantity is positive', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: QuantityPriceBar(
            priceRub: 450,
            oldPriceRub: 600,
            quantity: 2,
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2 × ${formatPriceRub(450)}'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.style?.decoration == TextDecoration.lineThrough,
      ),
      findsNothing,
    );
  });
}
