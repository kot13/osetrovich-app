import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/features/home/domain/banner.dart';
import 'package:osetrovich/features/home/domain/banner_link_handler.dart';

void main() {
  testWidgets('external link does not throw', (tester) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: ElevatedButton(
            onPressed:
                () => handleBannerLink(
                  context,
                  const BannerLink(
                    type: BannerLinkType.external,
                    url: 'https://osetrovich.ru',
                  ),
                ),
            child: const Text('open'),
          ),
        ),
      ),
    ],
  );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('open'));
    await tester.pump();
  });

  testWidgets('product link navigates to product route', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) => Scaffold(
                body: ElevatedButton(
                  onPressed:
                      () => handleBannerLink(
                        context,
                        const BannerLink(
                          type: BannerLinkType.product,
                          targetId: 'p-fish-0',
                        ),
                      ),
                  child: const Text('product'),
                ),
              ),
        ),
        GoRoute(
          path: '/catalog/product/:id',
          builder:
              (context, state) =>
                  Scaffold(body: Text('product-${state.pathParameters['id']}')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('product'));
    await tester.pumpAndSettle();

    expect(find.text('product-p-fish-0'), findsOneWidget);
  });

  testWidgets('none link does nothing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => handleBannerLink(context, BannerLink.none()),
              child: const Text('none'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('none'));
    await tester.pump();
    expect(find.text('none'), findsOneWidget);
  });
}
