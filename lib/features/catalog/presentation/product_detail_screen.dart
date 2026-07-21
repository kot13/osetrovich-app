import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/analytics/analytics_providers.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';
import 'package:osetrovich/core/widgets/empty_state.dart';
import 'package:osetrovich/core/widgets/loading_indicator.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/catalog/data/catalog_repository.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/product_image_gallery.dart';
import 'package:osetrovich/features/catalog/presentation/widgets/quantity_price_bar.dart';

final productDetailProvider = FutureProvider.family<ProductDetail, int>((
  ref,
  id,
) {
  return ref.read(catalogRepositoryProvider).getProductById(id);
});

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(analyticsServiceProvider)
            .reportProductView(widget.productId.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      // Внутри MainShell — не конфликтовать с внешним Scaffold и его Tab Bar.
      primary: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(AppStrings.tabCatalog),
      ),
      body: detailAsync.when(
        loading: () => const LoadingIndicator(),
        error:
            (_, __) => EmptyState(
              message: AppStrings.productNotFound,
              actionLabel: AppStrings.back,
              onAction: () => context.pop(),
            ),
        data:
            (product) => Column(
              children: [
                Expanded(child: _ProductDetailBody(product: product)),
                _ProductDetailBar(product: product),
              ],
            ),
      ),
    );
  }
}

class _ProductDetailBody extends StatelessWidget {
  const _ProductDetailBody({required this.product});

  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductImageGallery(imageUrls: product.imageUrls),
          const SizedBox(height: 16),
          Text(
            product.name,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.weightLabel,
            style: TextStyle(
              color: AppColors.dark.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatPriceRub(product.priceRub),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            product.description,
            style: const TextStyle(
              color: AppColors.dark,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailBar extends ConsumerWidget {
  const _ProductDetailBar({required this.product});

  final ProductDetail product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(
      cartNotifierProvider.select((cart) => cart[product.id] ?? 0),
    );
    final cart = ref.read(cartNotifierProvider.notifier);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child:
            quantity > 0
                ? QuantityPriceBar(
                  mode: QuantityPriceBarMode.detail,
                  priceRub: product.priceRub,
                  quantity: quantity,
                  onIncrement: () => cart.increment(product.id),
                  onDecrement: () => cart.decrement(product.id),
                )
                : Align(
                  alignment: Alignment.centerLeft,
                  child: QuantityPriceBar(
                    mode: QuantityPriceBarMode.detail,
                    priceRub: product.priceRub,
                    quantity: quantity,
                    onIncrement: () => cart.increment(product.id),
                    onDecrement: () => cart.decrement(product.id),
                  ),
                ),
      ),
    );
  }
}
