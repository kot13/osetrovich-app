import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/promotions/domain/promotion_article.dart';
import 'package:osetrovich/features/promotions/domain/promotion_type.dart';

class PromotionsRepository {
  PromotionsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PromotionArticleSummary>> getArticles(PromotionType type) {
    return _apiClient.getPromotionArticles(type);
  }

  Future<PromotionArticleDetail> getArticleById(String id) {
    return _apiClient.getPromotionArticleById(id);
  }
}

final promotionsRepositoryProvider = Provider<PromotionsRepository>((ref) {
  return PromotionsRepository(ref.watch(apiClientProvider));
});
