import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/catalog/data/catalog_repository.dart';
import 'package:osetrovich/features/catalog/domain/categories_provider.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';

class ProductsUiState {
  const ProductsUiState({
    this.items = const [],
    this.categoryId = kAllCategoriesId,
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.errorMessage,
    this.loadMoreError,
  });

  final List<ProductSummary> items;
  final int categoryId;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String? loadMoreError;

  bool get isEmpty =>
      !isLoadingInitial && items.isEmpty && errorMessage == null;

  ProductsUiState copyWith({
    List<ProductSummary>? items,
    int? categoryId,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    String? loadMoreError,
    bool clearError = false,
    bool clearLoadMoreError = false,
  }) {
    return ProductsUiState(
      items: items ?? this.items,
      categoryId: categoryId ?? this.categoryId,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}

class ProductsNotifier extends Notifier<ProductsUiState> {
  static const _pageSize = 20;

  @override
  ProductsUiState build() {
    ref.listen(selectedCategoryIdProvider, (previous, next) {
      if (previous != null && previous != next) {
        selectCategory(next);
      }
    });
    Future.microtask(
      () => selectCategory(ref.read(selectedCategoryIdProvider)),
    );
    return const ProductsUiState(
      isLoadingInitial: true,
      categoryId: kAllCategoriesId,
    );
  }

  Future<void> selectCategory(int categoryId) async {
    state = ProductsUiState(categoryId: categoryId, isLoadingInitial: true);

    await _fetchPage(categoryId: categoryId, offset: 0, append: false);
  }

  Future<void> reload() => selectCategory(state.categoryId);

  Future<void> loadMore() async {
    if (state.isLoadingInitial ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.errorMessage != null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);

    await _fetchPage(
      categoryId: state.categoryId,
      offset: state.items.length,
      append: true,
    );
  }

  Future<void> retryLoadMore() async {
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }
    await loadMore();
  }

  Future<void> _fetchPage({
    required int categoryId,
    required int offset,
    required bool append,
  }) async {
    try {
      final page = await ref
          .read(catalogRepositoryProvider)
          .getProducts(
            categoryId: categoryId,
            offset: offset,
            limit: _pageSize,
          );

      if (append) {
        if (state.categoryId != categoryId) {
          return;
        }
        state = ProductsUiState(
          categoryId: categoryId,
          items: [...state.items, ...page.items],
          isLoadingInitial: false,
          isLoadingMore: false,
          hasMore: page.hasMore,
        );
        return;
      }

      if (state.categoryId != categoryId) {
        return;
      }

      state = ProductsUiState(
        categoryId: categoryId,
        items: page.items,
        isLoadingInitial: false,
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } on ApiException catch (e) {
      _handleError(e.message, append: append, categoryId: categoryId);
    } on Object {
      _handleError(
        append ? AppStrings.loadMoreFailed : AppStrings.productsLoadFailed,
        append: append,
        categoryId: categoryId,
      );
    }
  }

  void _handleError(
    String message, {
    required bool append,
    required int categoryId,
  }) {
    if (append) {
      if (state.categoryId != categoryId) {
        return;
      }
      state = state.copyWith(isLoadingMore: false, loadMoreError: message);
    } else if (state.categoryId == categoryId) {
      state = ProductsUiState(categoryId: categoryId, errorMessage: message);
    }
  }
}

final productsNotifierProvider =
    NotifierProvider<ProductsNotifier, ProductsUiState>(ProductsNotifier.new);
