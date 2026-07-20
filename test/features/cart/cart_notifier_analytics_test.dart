import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/analytics/analytics_providers.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';

import '../../core/analytics/fake_analytics_service.dart';

void main() {
  test('increment reports add_to_cart analytics event', () {
    final fakeAnalytics = FakeAnalyticsService();
    final container = ProviderContainer(
      overrides: [analyticsServiceProvider.overrideWithValue(fakeAnalytics)],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment(1001);

    expect(fakeAnalytics.events, ['add_to_cart']);
    expect(fakeAnalytics.eventParams, [
      {'product_id': '1001'},
    ]);
  });
}
