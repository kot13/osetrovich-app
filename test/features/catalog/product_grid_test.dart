import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';
import 'package:osetrovich/features/catalog/domain/products_notifier.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/product_grid.dart';

void main() {
  const products = [
    ProductSummary(
      id: 'p1',
      name: 'Сёмга',
      weightLabel: '500 г',
      priceRub: 300,
      imageUrl: 'https://example.com/1.jpg',
      categoryIds: ['fish'],
    ),
    ProductSummary(
      id: 'p2',
      name: 'Форель',
      weightLabel: '400 г',
      priceRub: 450,
      imageUrl: 'https://example.com/2.jpg',
      categoryIds: ['fish'],
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
                categoryId: 'fish',
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
