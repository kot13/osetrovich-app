import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/catalog/domain/categories_provider.dart';

void main() {
  test('getCategories returns 12 categories', () async {
    final repo = CatalogRepository(MockApiClient());
    final categories = await repo.getCategories();
    expect(categories.length, 12);
    expect(categories.first.id, 'all');
    expect(categories.first.name, 'Все');
  });
}
