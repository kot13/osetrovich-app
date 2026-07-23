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
    priceRub: 600,
    oldPriceRub: 600,
    pricePerKgRub: 0,
    imageUrl: 'https://example.com/1.jpg',
    categoryIds: [1],
    sale: false,
    special: false,
    productOfWeek: false,
    pieceProduct: false,
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
      priceRub: 600,
      oldPriceRub: 900,
      pricePerKgRub: 2400,
      imageUrl: 'https://example.com/1.jpg',
      categoryIds: [1],
      sale: true,
      special: false,
      productOfWeek: false,
      pieceProduct: false,
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
      priceRub: 12000,
      oldPriceRub: 15000,
      pricePerKgRub: 12000,
      imageUrl: 'https://example.com/2.jpg',
      categoryIds: [2],
      sale: false,
      special: true,
      productOfWeek: false,
      pieceProduct: false,
    );
    const bothProduct = ProductSummary(
      id: 1001,
      name: 'Сёмга спец',
      weightLabel: '500 г',
      priceRub: 560,
      oldPriceRub: 800,
      pricePerKgRub: 0,
      imageUrl: 'https://example.com/3.jpg',
      categoryIds: [1],
      sale: true,
      special: true,
      productOfWeek: false,
      pieceProduct: false,
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
      priceRub: 600,
      oldPriceRub: 900,
      pricePerKgRub: 2400,
      imageUrl: 'https://example.com/1.jpg',
      categoryIds: [1],
      sale: false,
      special: false,
      productOfWeek: true,
      pieceProduct: false,
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

  testWidgets('product card centers placeholder when image url is missing', (
    tester,
  ) async {
    const noImageProduct = ProductSummary(
      id: 3000,
      name: 'Окунь морской',
      weightLabel: '1 кг',
      priceRub: 632,
      oldPriceRub: 800,
      pricePerKgRub: 0,
      imageUrl: '',
      categoryIds: [1],
      sale: true,
      special: true,
      productOfWeek: false,
      pieceProduct: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SizedBox(
              width: 168,
              height: 300,
              child: ProductCard(product: noImageProduct),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final iconFinder = find.byIcon(Icons.image_not_supported_outlined);
    expect(iconFinder, findsOneWidget);
    expect(
      find.ancestor(of: iconFinder, matching: find.byType(Center)),
      findsOneWidget,
    );

    final cardBox = tester.renderObject<RenderBox>(
      find.byType(ProductCard),
    );
    final iconBox = tester.renderObject<RenderBox>(iconFinder);
    final iconCenter = iconBox.localToGlobal(iconBox.size.center(Offset.zero));
    final cardCenter = cardBox.localToGlobal(cardBox.size.center(Offset.zero));

    expect(iconCenter.dx, closeTo(cardCenter.dx, 40));
  });

  testWidgets('product card shows strikethrough old price on add button', (
    tester,
  ) async {
    const discountedProduct = ProductSummary(
      id: 1000,
      name: 'Сёмга со скидкой',
      weightLabel: '300 г',
      priceRub: 1500,
      oldPriceRub: 2000,
      pricePerKgRub: 2400,
      imageUrl: 'https://example.com/1.jpg',
      categoryIds: [1],
      sale: true,
      special: false,
      productOfWeek: false,
      pieceProduct: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SizedBox(
              width: 168,
              height: 320,
              child: ProductCard(product: discountedProduct),
            ),
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

  testWidgets('product card hides old price when item is in cart', (
    tester,
  ) async {
    const discountedProduct = ProductSummary(
      id: 1000,
      name: 'Сёмга со скидкой',
      weightLabel: '300 г',
      priceRub: 1500,
      oldPriceRub: 2000,
      pricePerKgRub: 0,
      imageUrl: 'https://example.com/1.jpg',
      categoryIds: [1],
      sale: false,
      special: false,
      productOfWeek: false,
      pieceProduct: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartNotifierProvider.overrideWith(
            () => _SeededDiscountCartNotifier(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SizedBox(
              width: 168,
              height: 320,
              child: ProductCard(product: discountedProduct),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1 × ${formatPriceRub(450)}'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.style?.decoration == TextDecoration.lineThrough,
      ),
      findsNothing,
    );
  });

  testWidgets('product card shows price per kg when greater than zero', (
    tester,
  ) async {
    const productWithKgPrice = ProductSummary(
      id: 1000,
      name: 'Сёмга',
      weightLabel: '300 г',
      priceRub: 1500,
      oldPriceRub: 1500,
      pricePerKgRub: 2400,
      imageUrl: 'https://example.com/1.jpg',
      categoryIds: [1],
      sale: false,
      special: false,
      productOfWeek: false,
      pieceProduct: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SizedBox(
              width: 168,
              height: 320,
              child: ProductCard(product: productWithKgPrice),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(formatPricePerKgRub(2400)), findsOneWidget);
  });

  testWidgets('product card hides price per kg when zero', (tester) async {
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

    expect(find.textContaining('/кг'), findsNothing);
  });

  testWidgets('product card shows special total instead of price per kg', (
    tester,
  ) async {
    const specialProduct = ProductSummary(
      id: 2000,
      name: 'Икра',
      weightLabel: '100 г',
      priceRub: 12000,
      oldPriceRub: 15000,
      pricePerKgRub: 12000,
      imageUrl: 'https://example.com/2.jpg',
      categoryIds: [2],
      sale: false,
      special: true,
      productOfWeek: false,
      pieceProduct: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SizedBox(
              width: 168,
              height: 320,
              child: ProductCard(product: specialProduct),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(formatPriceRub(1200)), findsOneWidget);
    expect(find.text(formatPricePerKgRub(12000)), findsNothing);
    expect(find.text('${formatPriceRub(1200)} +'), findsOneWidget);
  });

  testWidgets('piece product can be added to cart from card', (tester) async {
    const pieceProduct = ProductSummary(
      id: 1002,
      name: 'Штучный товар',
      weightLabel: '1 шт',
      priceRub: 510,
      oldPriceRub: 510,
      pricePerKgRub: 1800,
      imageUrl: 'https://example.com/1.jpg',
      categoryIds: [1],
      sale: false,
      special: false,
      productOfWeek: false,
      pieceProduct: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SizedBox(
              width: 168,
              height: 320,
              child: ProductCard(product: pieceProduct),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('${formatPriceRub(510)} +'));
    await tester.pump();

    expect(find.text('1 × ${formatPriceRub(510)}'), findsOneWidget);
  });
}

class _SeededCartNotifier extends CartNotifier {
  @override
  Map<int, int> build() => {1001: 2};
}

class _SeededDiscountCartNotifier extends CartNotifier {
  @override
  Map<int, int> build() => {1000: 1};
}
