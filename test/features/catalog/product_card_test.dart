import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/product_card.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/quantity_price_bar.dart';

void main() {
  const product = ProductSummary(
    id: 1001,
    name: 'Сёмга слабосолёная',
    weightLabel: '500 г',
    priceRub: 300,
    oldPriceRub: 300,
    imageUrl: 'https://example.com/1.jpg',
    categoryIds: [1],
    sale: false,
    special: false,
    productOfWeek: false,
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

  testWidgets('product card shows sale badge', (tester) async {
    const saleProduct = ProductSummary(
      id: 1000,
      name: 'Акционная сёмга',
      weightLabel: '500 г',
      priceRub: 300,
      oldPriceRub: 450,
      imageUrl: 'https://example.com/1.jpg',
      categoryIds: [1],
      sale: true,
      special: false,
      productOfWeek: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SizedBox(
              width: 168,
              height: 300,
              child: ProductCard(product: saleProduct),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.badgeSale), findsOneWidget);
    expect(find.text(AppStrings.badgeSpecialPrice), findsNothing);
  });

  testWidgets('product card shows special and both badges', (tester) async {
    const specialProduct = ProductSummary(
      id: 2000,
      name: 'Икра',
      weightLabel: '100 г',
      priceRub: 1200,
      oldPriceRub: 1500,
      imageUrl: 'https://example.com/2.jpg',
      categoryIds: [2],
      sale: false,
      special: true,
      productOfWeek: false,
    );
    const bothProduct = ProductSummary(
      id: 1001,
      name: 'Сёмга спец',
      weightLabel: '500 г',
      priceRub: 280,
      oldPriceRub: 400,
      imageUrl: 'https://example.com/3.jpg',
      categoryIds: [1],
      sale: true,
      special: true,
      productOfWeek: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Row(
              children: const [
                SizedBox(
                  width: 168,
                  height: 300,
                  child: ProductCard(product: specialProduct),
                ),
                SizedBox(
                  width: 168,
                  height: 300,
                  child: ProductCard(product: bothProduct),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.badgeSpecialPrice), findsNWidgets(2));
    expect(find.text(AppStrings.badgeSale), findsOneWidget);
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

  testWidgets('product card shows product of week badge', (tester) async {
    const weekProduct = ProductSummary(
      id: 1000,
      name: 'Сёмга недели',
      weightLabel: '500 г',
      priceRub: 300,
      oldPriceRub: 450,
      imageUrl: 'https://example.com/1.jpg',
      categoryIds: [1],
      sale: false,
      special: false,
      productOfWeek: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SizedBox(
              width: 168,
              height: 300,
              child: ProductCard(product: weekProduct),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(AppStrings.badgeProductOfWeek), findsOneWidget);
  });
}

class _SeededCartNotifier extends CartNotifier {
  @override
  Map<int, int> build() => {1001: 2};
}
