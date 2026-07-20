import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/cart/domain/cart_line_item_view.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/cart/presentation/widgets/cart_line_tile.dart';

void main() {
  const line = CartLineItemView(
    productId: 1000,
    name: 'Сёмга',
    weightLabel: '500 г',
    priceRub: 450,
    imageUrl: 'https://example.com/image.jpg',
    quantity: 2,
  );

  testWidgets('cart line tile shows product info and quantity controls', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(cartNotifierProvider.notifier).increment(1000);
    container.read(cartNotifierProvider.notifier).increment(1000);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: CartLineTile(line: line)),
        ),
      ),
    );

    expect(find.text('Сёмга'), findsOneWidget);
    expect(find.text('500 г'), findsOneWidget);
    expect(find.text('900\u00A0₽'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
  });

  testWidgets('cart line tile increment updates quantity label', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(cartNotifierProvider.notifier).increment(1000);
    container.read(cartNotifierProvider.notifier).increment(1000);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: CartLineTile(line: line)),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.textContaining('3 ×'), findsOneWidget);
    expect(container.read(cartNotifierProvider)[1000], 3);
  });
}
