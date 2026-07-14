import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';

void main() {
  test('cart notifier increment and decrement', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartNotifierProvider.notifier);

    notifier.increment('p1');
    expect(container.read(cartNotifierProvider), {'p1': 1});
    expect(container.read(cartDistinctCountProvider), 1);

    notifier.increment('p1');
    expect(container.read(cartNotifierProvider), {'p1': 2});
    expect(container.read(cartDistinctCountProvider), 1);

    notifier.increment('p2');
    expect(container.read(cartDistinctCountProvider), 2);

    notifier.decrement('p1');
    expect(container.read(cartNotifierProvider), {'p1': 1, 'p2': 1});

    notifier.decrement('p1');
    expect(container.read(cartNotifierProvider), {'p2': 1});
    expect(container.read(cartDistinctCountProvider), 1);

    notifier.decrement('p2');
    expect(container.read(cartNotifierProvider), isEmpty);
    expect(container.read(cartDistinctCountProvider), 0);
  });

  test('clear removes all items', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartNotifierProvider.notifier);
    notifier.increment('p1');
    notifier.increment('p2');

    notifier.clear();

    expect(container.read(cartNotifierProvider), isEmpty);
    expect(container.read(cartDistinctCountProvider), 0);
  });
}
