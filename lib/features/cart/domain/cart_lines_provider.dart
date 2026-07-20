import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/cart/domain/cart_line_item_view.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/catalog/data/catalog_repository.dart';

final cartLinesProvider = FutureProvider<List<CartLineItemView>>((ref) async {
  final cart = ref.watch(cartNotifierProvider);
  if (cart.isEmpty) {
    return [];
  }

  final repository = ref.watch(catalogRepositoryProvider);
  final lines = <CartLineItemView>[];
  final unavailableIds = <int>[];

  for (final entry in cart.entries) {
    try {
      final product = await repository.getProductById(entry.key);
      lines.add(CartLineItemView.fromProduct(product, entry.value));
    } on ApiException catch (e) {
      if (e.code == 'NOT_FOUND') {
        unavailableIds.add(entry.key);
      } else {
        rethrow;
      }
    }
  }

  if (unavailableIds.isNotEmpty) {
    Future.microtask(() {
      final cartNotifier = ref.read(cartNotifierProvider.notifier);
      for (final id in unavailableIds) {
        cartNotifier.remove(id);
      }
    });
  }

  return lines;
});
