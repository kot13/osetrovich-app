import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {};

  int quantityOf(String productId) => state[productId] ?? 0;

  bool isInCart(String productId) => quantityOf(productId) > 0;

  void increment(String productId) {
    final current = quantityOf(productId);
    state = {...state, productId: current + 1};
  }

  void decrement(String productId) {
    final current = quantityOf(productId);
    if (current <= 1) {
      final next = Map<String, int>.from(state)..remove(productId);
      state = next;
    } else {
      state = {...state, productId: current - 1};
    }
  }

  void add(String productId) => increment(productId);

  void remove(String productId) {
    if (!state.containsKey(productId)) {
      return;
    }
    final next = Map<String, int>.from(state)..remove(productId);
    state = next;
  }

  void clear() {
    state = {};
  }
}

final cartNotifierProvider = NotifierProvider<CartNotifier, Map<String, int>>(
  CartNotifier.new,
);

final cartDistinctCountProvider = Provider<int>((ref) {
  return ref.watch(cartNotifierProvider).length;
});
