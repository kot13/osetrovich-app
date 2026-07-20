class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.weightLabel,
    required this.priceRub,
    required this.oldPriceRub,
    required this.imageUrl,
    required this.categoryIds,
    required this.sale,
    required this.special,
  });

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      weightLabel: json['weightLabel'] as String,
      priceRub: json['priceRub'] as int,
      oldPriceRub: json['oldPriceRub'] as int,
      imageUrl: json['imageUrl'] as String,
      categoryIds:
          (json['categoryIds'] as List<dynamic>).map((e) => e as int).toList(),
      sale: json['sale'] as bool,
      special: json['special'] as bool,
    );
  }

  final int id;
  final String name;
  final String weightLabel;
  final int priceRub;
  final int oldPriceRub;
  final String imageUrl;
  final List<int> categoryIds;
  final bool sale;
  final bool special;
}

class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.weightLabel,
    required this.priceRub,
    required this.oldPriceRub,
    required this.imageUrls,
    required this.description,
    required this.categoryIds,
    required this.sale,
    required this.special,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final imageUrlsFromJson =
        (json['imageUrls'] as List<dynamic>?)
            ?.map((e) => e as String)
            .where((url) => url.isNotEmpty)
            .toList() ??
        <String>[];
    final imageUrl = json['imageUrl'] as String?;
    final imageUrls =
        imageUrlsFromJson.isNotEmpty
            ? imageUrlsFromJson
            : (imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : <String>[]);

    return ProductDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      weightLabel: json['weightLabel'] as String,
      priceRub: json['priceRub'] as int,
      oldPriceRub: json['oldPriceRub'] as int,
      imageUrls: imageUrls,
      description: json['description'] as String,
      categoryIds:
          (json['categoryIds'] as List<dynamic>).map((e) => e as int).toList(),
      sale: json['sale'] as bool,
      special: json['special'] as bool,
    );
  }

  final int id;
  final String name;
  final String weightLabel;
  final int priceRub;
  final int oldPriceRub;
  final List<String> imageUrls;
  final String description;
  final List<int> categoryIds;
  final bool sale;
  final bool special;
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
