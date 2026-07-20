import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/analytics/analytics_providers.dart';

class CartNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => {};

  int quantityOf(int productId) => state[productId] ?? 0;

  bool isInCart(int productId) => quantityOf(productId) > 0;

  void increment(int productId) {
    final current = quantityOf(productId);
    state = {...state, productId: current + 1};
    ref.read(analyticsServiceProvider).reportAddToCart(productId.toString());
  }

  void decrement(int productId) {
    final current = quantityOf(productId);
    if (current <= 1) {
      final next = Map<int, int>.from(state)..remove(productId);
      state = next;
    } else {
      state = {...state, productId: current - 1};
    }
  }

  void add(int productId) => increment(productId);

  void addQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      return;
    }
    final current = quantityOf(productId);
    state = {...state, productId: current + quantity};
    ref.read(analyticsServiceProvider).reportAddToCart(productId.toString());
  }

  void remove(int productId) {
    if (!state.containsKey(productId)) {
      return;
    }
    final next = Map<int, int>.from(state)..remove(productId);
    state = next;
  }

  void clear() {
    state = {};
  }
}

final cartNotifierProvider = NotifierProvider<CartNotifier, Map<int, int>>(
  CartNotifier.new,
);

final cartDistinctCountProvider = Provider<int>((ref) {
  return ref.watch(cartNotifierProvider).length;
});
