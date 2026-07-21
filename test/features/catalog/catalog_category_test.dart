import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';

void main() {
  test('withAllCategoryFirst prepends All when missing from API', () {
    final result = withAllCategoryFirst([
      const CatalogCategory(id: kCategoryFish, name: 'Рыба', sortOrder: 1),
      const CatalogCategory(id: kCategoryCaviar, name: 'Икра', sortOrder: 2),
    ]);

    expect(result.first.id, kAllCategoriesId);
    expect(result.first.name, kAllCategoriesName);
    expect(result.length, 3);
  });

  test('withAllCategoryFirst deduplicates and normalizes All category', () {
    final result = withAllCategoryFirst([
      const CatalogCategory(
        id: kAllCategoriesId,
        name: 'Старое',
        sortOrder: 99,
      ),
      const CatalogCategory(id: kCategoryFish, name: 'Рыба', sortOrder: 1),
    ]);

    expect(result.first.id, kAllCategoriesId);
    expect(result.first.name, kAllCategoriesName);
    expect(result.where((c) => c.id == kAllCategoriesId).length, 1);
    expect(result.length, 2);
  });
}
