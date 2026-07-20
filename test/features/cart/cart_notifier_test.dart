import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';

void main() {
  test('cart notifier increment and decrement', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartNotifierProvider.notifier);

    notifier.increment(1001);
    expect(container.read(cartNotifierProvider), {1001: 1});
    expect(container.read(cartDistinctCountProvider), 1);

    notifier.increment(1001);
    expect(container.read(cartNotifierProvider), {1001: 2});
    expect(container.read(cartDistinctCountProvider), 1);

    notifier.increment(1002);
    expect(container.read(cartDistinctCountProvider), 2);

    notifier.decrement(1001);
    expect(container.read(cartNotifierProvider), {1001: 1, 1002: 1});

    notifier.decrement(1001);
    expect(container.read(cartNotifierProvider), {1002: 1});
    expect(container.read(cartDistinctCountProvider), 1);

    notifier.decrement(1002);
    expect(container.read(cartNotifierProvider), isEmpty);
    expect(container.read(cartDistinctCountProvider), 0);
  });

  test('clear removes all items', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartNotifierProvider.notifier);
    notifier.increment(1001);
    notifier.increment(1002);

    notifier.clear();

    expect(container.read(cartNotifierProvider), isEmpty);
    expect(container.read(cartDistinctCountProvider), 0);
  });
}
