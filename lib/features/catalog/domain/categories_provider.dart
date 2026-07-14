import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatalogRepository {
  CatalogRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CatalogCategory>> getCategories() {
    return _apiClient.getCategories();
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(apiClientProvider));
});

class CategoriesNotifier extends AsyncNotifier<List<CatalogCategory>> {
  @override
  Future<List<CatalogCategory>> build() async {
    return ref.read(catalogRepositoryProvider).getCategories();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(catalogRepositoryProvider).getCategories(),
    );
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<CatalogCategory>>(
      CategoriesNotifier.new,
    );

final selectedCategoryIdProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(
      SelectedCategoryNotifier.new,
    );

class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void select(String id) => state = id;
}
