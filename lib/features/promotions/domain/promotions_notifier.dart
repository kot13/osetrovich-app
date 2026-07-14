import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/features/promotions/data/promotions_repository.dart';
import 'package:osetrovich/features/promotions/domain/promotion_article.dart';
import 'package:osetrovich/features/promotions/domain/selected_type_provider.dart';

class PromotionsNotifier extends AsyncNotifier<List<PromotionArticleSummary>> {
  @override
  Future<List<PromotionArticleSummary>> build() async {
    final type = ref.watch(selectedPromotionTypeProvider);
    return ref.read(promotionsRepositoryProvider).getArticles(type);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final type = ref.read(selectedPromotionTypeProvider);
      return ref.read(promotionsRepositoryProvider).getArticles(type);
    });
  }
}

final promotionsNotifierProvider =
    AsyncNotifierProvider<PromotionsNotifier, List<PromotionArticleSummary>>(
      PromotionsNotifier.new,
    );
