class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.weightLabel,
    required this.priceRub,
    required this.imageUrl,
    required this.categoryIds,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      weightLabel: json['weightLabel'] as String,
      priceRub: json['priceRub'] as int,
      imageUrl: json['imageUrl'] as String,
      categoryIds:
          (json['categoryIds'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
    );
  }

  final String id;
  final String name;
  final String weightLabel;
  final int priceRub;
  final String imageUrl;
  final List<String> categoryIds;
}

class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.weightLabel,
    required this.priceRub,
    required this.imageUrls,
    required this.description,
    required this.categoryIds,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      weightLabel: json['weightLabel'] as String,
      priceRub: json['priceRub'] as int,
      imageUrls:
          (json['imageUrls'] as List<dynamic>).map((e) => e as String).toList(),
      description: json['description'] as String,
      categoryIds:
          (json['categoryIds'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
    );
  }

  final String id;
  final String name;
  final String weightLabel;
  final int priceRub;
  final List<String> imageUrls;
  final String description;
  final List<String> categoryIds;
}

class ProductListPage {
  const ProductListPage({
    required this.items,
    required this.total,
    required this.hasMore,
    required this.offset,
    required this.limit,
  });

  factory ProductListPage.fromJson(Map<String, dynamic> json) {
    return ProductListPage(
      items:
          (json['items'] as List<dynamic>)
              .map((e) => ProductSummary.fromJson(e as Map<String, dynamic>))
              .toList(),
      total: json['total'] as int,
      hasMore: json['hasMore'] as bool,
      offset: json['offset'] as int,
      limit: json['limit'] as int,
    );
  }

  final List<ProductSummary> items;
  final int total;
  final bool hasMore;
  final int offset;
  final int limit;
}
