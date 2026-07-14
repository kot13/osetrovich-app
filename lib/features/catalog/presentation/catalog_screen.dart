import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/empty_state.dart';
import 'package:osetrovich/core/widgets/loading_indicator.dart';
import 'package:osetrovich/features/catalog/domain/categories_provider.dart';
import 'package:osetrovich/features/catalog/domain/products_notifier.dart';
import 'package:osetrovich/features/catalog/presentation/category_chips.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/product_grid.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedId = ref.watch(selectedCategoryIdProvider);
    final productsState = ref.watch(productsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabCatalog)),
      body: categoriesAsync.when(
        loading: () => const LoadingIndicator(),
        error:
            (_, __) => EmptyState(
              message: AppStrings.categoriesLoadFailed,
              actionLabel: AppStrings.retry,
              onAction: () => ref.read(categoriesProvider.notifier).reload(),
            ),
        data:
            (categories) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CategoryChips(
                  categories: categories,
                  selectedId: selectedId,
                  onSelected:
                      (id) => ref
                          .read(selectedCategoryIdProvider.notifier)
                          .select(id),
                ),
                Expanded(child: _ProductsArea(productsState: productsState)),
              ],
            ),
      ),
    );
  }
}

class _ProductsArea extends ConsumerWidget {
  const _ProductsArea({required this.productsState});

  final ProductsUiState productsState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (productsState.isLoadingInitial) {
      return const LoadingIndicator();
    }

    if (productsState.errorMessage != null) {
      return EmptyState(
        message: productsState.errorMessage!,
        actionLabel: AppStrings.retry,
        onAction: () => ref.read(productsNotifierProvider.notifier).reload(),
      );
    }

    if (productsState.isEmpty) {
      return const EmptyState(message: AppStrings.nothingFound);
    }

    return ProductGrid(productsState: productsState);
  }
}
