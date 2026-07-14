import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:osetrovich/app.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/promotions/presentation/widgets/promotion_article_card.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('promotions flow chips list detail back', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text(AppStrings.tabPromotions));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(PromotionArticleCard), findsWidgets);

    await tester.tap(find.textContaining('икру').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.textContaining('🎉'), findsWidgets);

    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(
      tester
          .widget<FilterChip>(
            find.widgetWithText(FilterChip, AppStrings.chipAll),
          )
          .selected,
      isTrue,
    );
  });
}
