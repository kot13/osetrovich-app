import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_line_item_view.dart';
import 'package:osetrovich/features/cart/domain/cart_lines_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/catalog/data/catalog_repository.dart';
import 'package:osetrovich/features/profile/domain/lemon_gift_preview.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';

List<CartLineItemView> buildCartDisplayLines({
  required List<CartLineItemView> cartLines,
  required bool isAuthenticated,
  required int? lemons,
  required bool cartIsEmpty,
  CartLineItemView? giftLine,
}) {
  if (!isAuthenticated ||
      lemons != 10 ||
      giftLine == null ||
      cartIsEmpty ||
      cartLines.isEmpty) {
    return cartLines;
  }

  return [...cartLines, giftLine];
}

final cartDisplayLinesProvider = FutureProvider<List<CartLineItemView>>((
  ref,
) async {
  final cartLines = await ref.watch(cartLinesProvider.future);
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) {
    return cartLines;
  }

  final profile = ref.watch(profileNotifierProvider).valueOrNull;
  final cart = ref.watch(cartNotifierProvider);
  final lemonGift = profile?.lemonGift;

  CartLineItemView? giftLine;
  if (profile?.lemons == 10 &&
      lemonGift != null &&
      !cart.isEmpty &&
      cartLines.isNotEmpty) {
    var originalPriceRub = 0;
    try {
      final product = await ref
          .read(catalogRepositoryProvider)
          .getProductById(lemonGift.productId);
      originalPriceRub = product.priceRub;
    } on ApiException catch (e) {
      if (e.code != 'NOT_FOUND') {
        rethrow;
      }
    }
    giftLine = CartLineItemView.fromLemonGift(
      lemonGift,
      originalPriceRub: originalPriceRub,
    );
  }

  return buildCartDisplayLines(
    cartLines: cartLines,
    isAuthenticated: isAuthenticated,
    lemons: profile?.lemons,
    cartIsEmpty: cart.isEmpty,
    giftLine: giftLine,
  );
});
