import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/cart/domain/pending_checkout_provider.dart';

void main() {
  test('save persists address apartment and comment', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(pendingCheckoutProvider.notifier)
        .save(
          address: 'г. Санкт-Петербург, 1',
          apartment: '42',
          comment: 'комментарий',
        );

    final pending = container.read(pendingCheckoutProvider);
    expect(pending?.address, 'г. Санкт-Петербург, 1');
    expect(pending?.apartment, '42');
    expect(pending?.comment, 'комментарий');
  });

  test('clear resets state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(pendingCheckoutProvider.notifier)
        .save(address: 'адрес', apartment: '', comment: '');
    container.read(pendingCheckoutProvider.notifier).clear();

    expect(container.read(pendingCheckoutProvider), isNull);
  });
}
