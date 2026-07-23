import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';
import 'package:osetrovich/features/catalog/domain/products_notifier.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/product_grid.dart';

void main() {
  const products = [
    ProductSummary(
      id: 1001,
      name: 'Сёмга',
      weightLabel: '500 г',
      priceRub: 300,
      oldPriceRub: 300,
      pricePerKgRub: 0,
      imageUrl: 'https://example.com/1.jpg',
      categoryIds: [kCategoryFish],
      sale: false,
      special: false,
      productOfWeek: false,
      pieceProduct: false,
    ),
    ProductSummary(
      id: 1002,
      name: 'Форель',
      weightLabel: '400 г',
      priceRub: 450,
      oldPriceRub: 450,
      pricePerKgRub: 1800,
      imageUrl: 'https://example.com/2.jpg',
      categoryIds: [kCategoryFish],
      sale: false,
      special: false,
      productOfWeek: false,
      pieceProduct: true,
    ),
  ];

  testWidgets('product grid shows two columns', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ProductGrid(
              productsState: const ProductsUiState(
                items: products,
                categoryId: kCategoryFish,
                hasMore: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Сёмга'), findsOneWidget);
    expect(find.text('Форель'), findsOneWidget);

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
    );
  });

  testWidgets('product grid keeps scroll position after load more', (
    tester,
  ) async {
    List<ProductSummary> makeProducts(int count) {
      return List.generate(
        count,
        (index) => ProductSummary(
          id: 1000 + index,
          name: 'Товар $index',
          weightLabel: '500 г',
          priceRub: 300 + index,
          oldPriceRub: 300 + index,
          pricePerKgRub: 0,
          imageUrl: 'https://example.com/$index.jpg',
          categoryIds: const [kCategoryFish],
          sale: false,
          special: false,
          productOfWeek: false,
          pieceProduct: false,
        ),
      );
    }

    var productsState = ProductsUiState(
      items: makeProducts(20),
      categoryId: kCategoryFish,
      hasMore: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: ProductGrid(productsState: productsState),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(GridView), const Offset(0, -500));
    await tester.pumpAndSettle();

    final offsetBefore =
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(offsetBefore, greaterThan(0));

    productsState = ProductsUiState(
      items: makeProducts(40),
      categoryId: kCategoryFish,
      hasMore: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: ProductGrid(productsState: productsState),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final offsetAfter =
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(offsetAfter, greaterThan(0));
    expect(offsetAfter, closeTo(offsetBefore, 1));
  });
}
