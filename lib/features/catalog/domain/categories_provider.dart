import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/features/catalog/data/catalog_repository.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';

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
    NotifierProvider<SelectedCategoryNotifier, int>(
      SelectedCategoryNotifier.new,
    );

class SelectedCategoryNotifier extends Notifier<int> {
  @override
  int build() => kAllCategoriesId;

  void select(int id) => state = id;
}
