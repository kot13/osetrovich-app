import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/core/analytics/analytics_service.dart';
import 'package:osetrovich/core/push/appmetrica_push_service.dart';

class _MockAnalytics extends Mock implements AnalyticsService {}

void main() {
  late _MockAnalytics analytics;
  late AppMetricaPushService service;

  setUp(() {
    analytics = _MockAnalytics();
    when(() => analytics.setPushEnabled(any())).thenAnswer((_) async {});
    service = AppMetricaPushService(analytics);
  });

  test('syncPushEnabled updates analytics user profile', () async {
    await service.syncPushEnabled(true);

    verify(() => analytics.setPushEnabled(true)).called(1);
  });
}
