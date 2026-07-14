import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/promotions/presentation/promotion_detail_screen.dart';

void main() {
  testWidgets('promotion detail screen shows fields and back button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PromotionDetailScreen(articleId: 'promo-1'),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text(AppStrings.typePromotion), findsOneWidget);
    expect(find.textContaining('икру'), findsWidgets);
    expect(find.text('14 июля 2026'), findsOneWidget);
    expect(find.textContaining('🎉'), findsOneWidget);
  });

  testWidgets('promotion detail screen shows not found for unknown id', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PromotionDetailScreen(articleId: 'unknown'),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text(AppStrings.articleNotFound), findsOneWidget);
    expect(find.text(AppStrings.back), findsOneWidget);
  });
}
