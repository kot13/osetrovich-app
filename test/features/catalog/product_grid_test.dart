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
      imageUrl: 'https://example.com/1.jpg',
      categoryIds: [kCategoryFish],
      sale: false,
      special: false,
      productOfWeek: false,
    ),
    ProductSummary(
      id: 1002,
      name: 'Форель',
      weightLabel: '400 г',
      priceRub: 450,
      oldPriceRub: 450,
      imageUrl: 'https://example.com/2.jpg',
      categoryIds: [kCategoryFish],
      sale: false,
      special: false,
      productOfWeek: false,
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
}
