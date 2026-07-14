import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/promotions/data/promotions_repository.dart';
import 'package:osetrovich/features/promotions/domain/promotion_type.dart';

void main() {
  late PromotionsRepository repository;

  setUp(() {
    repository = PromotionsRepository(MockApiClient());
  });

  test('getArticles returns all types for all filter', () async {
    final articles = await repository.getArticles(PromotionType.all);

    expect(articles.length, 10);
    expect(articles.any((a) => a.type == PromotionType.promotion), isTrue);
    expect(articles.any((a) => a.type == PromotionType.news), isTrue);
  });

  test('getArticles returns promotions sorted newest first', () async {
    final articles = await repository.getArticles(PromotionType.promotion);

    expect(articles.length, 6);
    expect(articles.first.id, 'promo-1');
    expect(
      articles.first.publishedAt.isAfter(articles.last.publishedAt) ||
          articles.first.publishedAt.isAtSameMomentAs(
            articles.last.publishedAt,
          ),
      isTrue,
    );
  });

  test('getArticles returns news only for news type', () async {
    final articles = await repository.getArticles(PromotionType.news);

    expect(articles.length, 4);
    expect(articles.every((a) => a.type == PromotionType.news), isTrue);
  });

  test('getArticleById returns detail with bodyHtml', () async {
    final detail = await repository.getArticleById('promo-1');

    expect(detail.title, contains('икру'));
    expect(detail.bodyHtml, contains('<strong>'));
  });
}
