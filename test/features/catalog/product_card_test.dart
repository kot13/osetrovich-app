import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/product_card.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/quantity_price_bar.dart';

void main() {
  const product = ProductSummary(
    id: 'p1',
    name: 'Сёмга слабосолёная',
    weightLabel: '500 г',
    priceRub: 300,
    imageUrl: 'https://example.com/1.jpg',
    categoryIds: ['fish'],
  );

  testWidgets('product card shows price button when not in cart', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SizedBox(
              width: 168,
              height: 300,
              child: ProductCard(product: product),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('${formatPriceRub(300)} +'), findsOneWidget);
    expect(find.text('Сёмга слабосолёная'), findsOneWidget);
  });

  testWidgets('product card shows quantity bar and product info when in cart', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartNotifierProvider.overrideWith(() => _SeededCartNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SizedBox(
              width: 168,
              height: 300,
              child: ProductCard(product: product),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2 × ${formatPriceRub(300)}'), findsOneWidget);
    expect(find.text('Сёмга слабосолёная'), findsOneWidget);
    expect(find.text('500 г'), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('add button matches compact bar height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: QuantityPriceBar(
            priceRub: 300,
            quantity: 0,
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final addBar = tester.widget<SizedBox>(
      find
          .ancestor(
            of: find.text('${formatPriceRub(300)} +'),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.height == kCompactBarHeight,
            ),
          )
          .first,
    );
    expect(addBar.height, kCompactBarHeight);
  });
}

class _SeededCartNotifier extends CartNotifier {
  @override
  Map<String, int> build() => {'p1': 2};
}
