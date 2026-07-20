/// Синтетическая категория «Все товары» (клиент / мок, не id с сервера).
const kAllCategoriesId = 0;

const kCategoryFish = 1;
const kCategoryCaviar = 2;
const kCategoryCrabs = 3;
const kCategorySeaweed = 4;
const kCategorySpices = 5;
const kCategorySauces = 6;
const kCategoryShrimp = 7;
const kCategoryMollusks = 8;
const kCategoryCanned = 9;
const kCategoryForFish = 10;
const kCategorySemiFinished = 11;

String categoryIdToApiQuery(int categoryId) =>
    categoryId == kAllCategoriesId ? 'all' : '$categoryId';

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int,
    );
  }

  final int id;
  final String name;
  final int sortOrder;
}
