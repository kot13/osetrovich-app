import 'package:osetrovich/core/l10n/app_strings.dart';

enum PromotionType {
  all('all'),
  promotion('promotion'),
  news('news');

  const PromotionType(this.apiValue);

  final String apiValue;

  static PromotionType fromApi(String value) {
    return PromotionType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => throw FormatException('Unknown promotion type: $value'),
    );
  }

  String get chipLabel => switch (this) {
    PromotionType.all => AppStrings.chipAll,
    PromotionType.promotion => AppStrings.chipPromotions,
    PromotionType.news => AppStrings.chipNews,
  };

  String get typeLabel => switch (this) {
    PromotionType.all => AppStrings.chipAll,
    PromotionType.promotion => AppStrings.typePromotion,
    PromotionType.news => AppStrings.typeNews,
  };
}
