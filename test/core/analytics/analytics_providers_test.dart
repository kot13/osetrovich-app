import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/analytics/analytics_providers.dart';
import 'package:osetrovich/core/analytics/no_op_analytics_service.dart';
import 'package:osetrovich/core/push/no_op_push_service.dart';
import 'package:osetrovich/core/push/push_providers.dart';

void main() {
  test('analyticsServiceProvider returns NoOp without API key', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(analyticsServiceProvider),
      isA<NoOpAnalyticsService>(),
    );
  });

  test('pushServiceProvider returns NoOp when push is not activated', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(pushServiceProvider), isA<NoOpPushService>());
  });
}
