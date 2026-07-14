import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/cart/domain/cart_lines_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';

void main() {
  test('cartLinesProvider resolves products and line totals', () async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment('p-fish-0');
    container.read(cartNotifierProvider.notifier).increment('p-fish-0');
    container.read(cartNotifierProvider.notifier).increment('p-caviar-0');

    final lines = await container.read(cartLinesProvider.future);

    expect(lines, hasLength(2));
    expect(lines.first.quantity, 2);
    expect(lines.first.lineTotalRub, lines.first.priceRub * 2);
  });

  test('cartLinesProvider removes unavailable products from cart', () async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment('unknown-id');

    final lines = await container.read(cartLinesProvider.future);
    await Future<void>.delayed(Duration.zero);

    expect(lines, isEmpty);
    expect(container.read(cartNotifierProvider), isEmpty);
  });
}
