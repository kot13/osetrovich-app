import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatalogRepository {
  CatalogRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CatalogCategory>> getCategories() {
    return _apiClient.getCategories();
  }

  Future<ProductListPage> getProducts({
    required String categoryId,
    required int offset,
    required int limit,
  }) {
    return _apiClient.getProducts(
      categoryId: categoryId,
      offset: offset,
      limit: limit,
    );
  }

  Future<ProductDetail> getProductById(String id) {
    return _apiClient.getProductById(id);
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(apiClientProvider));
});
