import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/loading_indicator.dart';
import 'package:osetrovich/features/catalog/domain/products_notifier.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/product_card.dart';

class ProductGrid extends ConsumerStatefulWidget {
  const ProductGrid({super.key, required this.productsState});

  final ProductsUiState productsState;

  @override
  ConsumerState<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends ConsumerState<ProductGrid> {
  final _scrollController = ScrollController();
  String? _lastCategoryId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final categoryId = widget.productsState.categoryId;
    if (_lastCategoryId != categoryId) {
      _lastCategoryId = categoryId;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(productsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.productsState;
    final itemCount =
        state.items.length +
        (state.isLoadingMore ? 1 : 0) +
        (state.loadMoreError != null ? 1 : 0);

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.56,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < state.items.length) {
          return ProductCard(product: state.items[index]);
        }

        if (state.isLoadingMore && index == state.items.length) {
          return const Center(child: LoadingIndicator());
        }

        if (state.loadMoreError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.loadMoreError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
                TextButton(
                  onPressed:
                      () =>
                          ref
                              .read(productsNotifierProvider.notifier)
                              .retryLoadMore(),
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
