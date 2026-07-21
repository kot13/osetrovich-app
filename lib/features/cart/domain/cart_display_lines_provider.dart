import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_line_item_view.dart';
import 'package:osetrovich/features/cart/domain/cart_lines_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/profile/domain/lemon_gift_preview.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';

List<CartLineItemView> buildCartDisplayLines({
  required List<CartLineItemView> cartLines,
  required bool isAuthenticated,
  required int? lemons,
  required LemonGiftPreview? lemonGift,
  required bool cartIsEmpty,
}) {
  if (!isAuthenticated ||
      lemons != 10 ||
      lemonGift == null ||
      cartIsEmpty ||
      cartLines.isEmpty) {
    return cartLines;
  }

  return [...cartLines, CartLineItemView.fromLemonGift(lemonGift)];
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

  return buildCartDisplayLines(
    cartLines: cartLines,
    isAuthenticated: isAuthenticated,
    lemons: profile?.lemons,
    lemonGift: profile?.lemonGift,
    cartIsEmpty: cart.isEmpty,
  );
});
