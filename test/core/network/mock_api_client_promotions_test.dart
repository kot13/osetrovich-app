import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/promotions/domain/promotion_type.dart';

void main() {
  late MockApiClient client;

  setUp(() {
    client = MockApiClient();
  });

  test('getPromotionArticleById returns html body for known article', () async {
    final detail = await client.getPromotionArticleById('promo-1');

    expect(detail.bodyHtml, contains('икру'));
    expect(detail.type, PromotionType.promotion);
  });

  test('getPromotionArticleById throws for unknown id', () async {
    expect(
      () => client.getPromotionArticleById('unknown'),
      throwsA(isA<ApiException>()),
    );
  });

  test('getPromotionArticleById throws for unpublished article', () async {
    expect(
      () => client.getPromotionArticleById('unpublished-demo'),
      throwsA(isA<ApiException>()),
    );
  });
}
