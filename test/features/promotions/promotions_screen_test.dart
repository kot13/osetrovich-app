import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/promotions/presentation/promotion_detail_screen.dart';
import 'package:osetrovich/features/promotions/presentation/promotions_screen.dart';
import 'package:osetrovich/features/promotions/presentation/widgets/promotion_article_card.dart';

void main() {
  testWidgets('promotions screen shows chips and promotion feed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PromotionsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.chipAll), findsOneWidget);
    expect(find.text(AppStrings.chipPromotions), findsWidgets);
    expect(find.text(AppStrings.chipNews), findsOneWidget);

    final allChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, AppStrings.chipAll),
    );
    expect(allChip.selected, isTrue);
    expect(find.byType(PromotionArticleCard), findsWidgets);
    expect(find.text(AppStrings.nothingFound), findsNothing);
  });

  testWidgets('promotions screen switches to news and shows empty or list', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PromotionsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text(AppStrings.chipNews));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final newsChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, AppStrings.chipNews),
    );
    expect(newsChip.selected, isTrue);
    expect(find.byType(PromotionArticleCard), findsWidgets);
  });

  testWidgets('promotions screen opens detail route on card tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/promotions',
      routes: [
        GoRoute(
          path: '/promotions',
          builder: (context, state) => const PromotionsScreen(),
          routes: [
            GoRoute(
              path: 'article/:id',
              builder: (context, state) {
                return PromotionDetailScreen(
                  articleId: state.pathParameters['id']!,
                );
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.textContaining('икру').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PromotionDetailScreen), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.textContaining('икру'), findsWidgets);
  });
}
