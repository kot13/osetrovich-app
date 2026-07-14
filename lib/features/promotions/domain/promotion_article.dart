import 'package:osetrovich/features/promotions/domain/promotion_type.dart';

class PromotionArticleSummary {
  const PromotionArticleSummary({
    required this.id,
    required this.type,
    required this.title,
    required this.publishedAt,
    required this.imageUrl,
  });

  final String id;
  final PromotionType type;
  final String title;
  final DateTime publishedAt;
  final String imageUrl;

  factory PromotionArticleSummary.fromJson(Map<String, dynamic> json) {
    return PromotionArticleSummary(
      id: json['id'] as String,
      type: PromotionType.fromApi(json['type'] as String),
      title: json['title'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      imageUrl: json['imageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.apiValue,
      'title': title,
      'publishedAt': publishedAt.toUtc().toIso8601String(),
      'imageUrl': imageUrl,
    };
  }
}

class PromotionArticleDetail extends PromotionArticleSummary {
  const PromotionArticleDetail({
    required super.id,
    required super.type,
    required super.title,
    required super.publishedAt,
    required super.imageUrl,
    required this.bodyHtml,
  });

  final String bodyHtml;

  factory PromotionArticleDetail.fromJson(Map<String, dynamic> json) {
    return PromotionArticleDetail(
      id: json['id'] as String,
      type: PromotionType.fromApi(json['type'] as String),
      title: json['title'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      imageUrl: json['imageUrl'] as String,
      bodyHtml: json['bodyHtml'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {...super.toJson(), 'bodyHtml': bodyHtml};
  }
}
