class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int,
    );
  }

  final String id;
  final String name;
  final int sortOrder;
}
