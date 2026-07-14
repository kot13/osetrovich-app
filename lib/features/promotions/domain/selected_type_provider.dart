import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/features/promotions/domain/promotion_type.dart';

final selectedPromotionTypeProvider =
    NotifierProvider<SelectedPromotionTypeNotifier, PromotionType>(
      SelectedPromotionTypeNotifier.new,
    );

class SelectedPromotionTypeNotifier extends Notifier<PromotionType> {
  @override
  PromotionType build() => PromotionType.all;

  void select(PromotionType type) => state = type;
}
