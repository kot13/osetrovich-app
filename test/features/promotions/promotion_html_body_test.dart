import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/features/promotions/presentation/widgets/promotion_html_body.dart';

void main() {
  testWidgets('promotion html body renders strong text and emoji', (
    tester,
  ) async {
    const html =
        '<p>Текст <strong>жирный</strong> 🎉</p><ul><li>Пункт</li></ul>';

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: PromotionHtmlBody(html: html))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('жирный'), findsOneWidget);
    expect(find.textContaining('🎉'), findsOneWidget);
    expect(find.text('Пункт'), findsOneWidget);
  });

  testWidgets('promotion html body does not render script content', (
    tester,
  ) async {
    const html =
        '<p>Безопасный текст</p><script>alert("xss")</script><p>После</p>';

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: PromotionHtmlBody(html: html))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Безопасный'), findsOneWidget);
    expect(find.textContaining('После'), findsOneWidget);
    expect(find.textContaining('alert'), findsNothing);
    expect(find.textContaining('xss'), findsNothing);
  });

  testWidgets('opens osetrovich link inside app', (tester) async {
    const html =
        '<p><a href="osetrovich://catalog/product/1000">товар</a></p>';

    final router = GoRouter(
      initialLocation: '/promotions',
      routes: [
        GoRoute(
          path: '/promotions',
          builder:
              (context, state) =>
                  const Scaffold(body: PromotionHtmlBody(html: html)),
        ),
        GoRoute(
          path: '/catalog/product/:id',
          builder:
              (context, state) =>
                  Text('Product ${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('товар'));
    await tester.pumpAndSettle();

    expect(find.text('Product 1000'), findsOneWidget);
  });
}
