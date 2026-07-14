import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/promotions/domain/promotion_article.dart';
import 'package:osetrovich/features/promotions/domain/promotion_type.dart';
import 'package:osetrovich/features/promotions/presentation/widgets/promotion_article_card.dart';

void main() {
  final article = PromotionArticleSummary(
    id: 'promo-1',
    type: PromotionType.promotion,
    title:
        'Очень длинный заголовок акции который должен обрезаться на второй строке',
    publishedAt: DateTime.utc(2026, 7, 14),
    imageUrl: 'https://picsum.photos/seed/promo1/800/450',
  );

  testWidgets('promotion article card shows title date and image', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PromotionArticleCard(
              article: article,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.typePromotion), findsOneWidget);
    expect(find.textContaining('Очень длинный заголовок'), findsOneWidget);
    expect(find.text('14 июля 2026'), findsOneWidget);

    await tester.tap(find.byType(PromotionArticleCard));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
