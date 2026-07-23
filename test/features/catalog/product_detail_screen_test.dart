import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/catalog/presentation/product_detail_screen.dart';

void main() {
  testWidgets('product detail shows fields and detail bar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProductDetailScreen(productId: 1000),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.textContaining('слабосолёная'), findsWidgets);
    expect(find.text('300 г'), findsOneWidget);
    expect(find.text(formatPricePerKgRub(2400)), findsOneWidget);

    final oldPriceFinder = find.text(formatPriceForWeightLabel(600, '300 г'));
    expect(oldPriceFinder, findsOneWidget);
    expect(
      tester.widget<Text>(oldPriceFinder).style?.decoration,
      TextDecoration.lineThrough,
    );
    expect(find.text(formatPriceForWeightLabel(450, '300 г')), findsOneWidget);
    expect(find.text('${formatPriceRub(450)} +'), findsOneWidget);

    await tester.tap(find.textContaining(' +').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('1 ×'), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(oldPriceFinder, findsOneWidget);
    expect(
      tester.widget<Text>(oldPriceFinder).style?.decoration,
      TextDecoration.lineThrough,
    );
  });

  testWidgets('product detail renders inside nested shell scaffold', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: const ProductDetailScreen(productId: 1000),
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view),
                  label: 'Catalog',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.textContaining('слабосолёная'), findsWidgets);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text(AppStrings.tabCatalog), findsOneWidget);
    expect(find.text(formatPricePerKgRub(2400)), findsOneWidget);
    expect(find.text(formatPriceForWeightLabel(450, '300 г')), findsOneWidget);
    expect(find.text('${formatPriceRub(450)} +'), findsOneWidget);
  });

  testWidgets('product detail hides price per kg when zero', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProductDetailScreen(productId: 1001),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.textContaining('/кг'), findsNothing);
  });

  testWidgets('product detail increments via cart notifier', (tester) async {
    late ProviderContainer container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container:
            container = ProviderContainer(
              overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
            ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProductDetailScreen(productId: 1001),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.textContaining(' +').last);
    await tester.pumpAndSettle();

    expect(container.read(cartNotifierProvider)[1001], 1);
  });
}
