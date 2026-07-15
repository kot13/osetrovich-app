import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/analytics/analytics_events.dart';
import 'package:osetrovich/core/analytics/appmetrica_analytics_service.dart';

void main() {
  test('reportProductView sends contract event and params', () async {
    String? sentName;
    Map<String, Object>? sentParams;

    final service = AppMetricaAnalyticsService(
      sendEvent: (name, attrs) async {
        sentName = name;
        sentParams = attrs;
      },
    );

    service.reportProductView('p42');

    expect(sentName, AnalyticsEvents.productView);
    expect(sentParams, {'product_id': 'p42'});
  });

  test('reportOrderSuccess sends order_id and order_total', () async {
    String? sentName;
    Map<String, Object>? sentParams;

    final service = AppMetricaAnalyticsService(
      sendEvent: (name, attrs) async {
        sentName = name;
        sentParams = attrs;
      },
    );

    service.reportOrderSuccess(orderId: 'ord-9', orderTotalRub: 3200);

    expect(sentName, AnalyticsEvents.orderSuccess);
    expect(sentParams, {'order_id': 'ord-9', 'order_total': 3200});
  });

  test('setUserId delegates to profile id setter', () async {
    String? capturedId;

    final service = AppMetricaAnalyticsService(
      setUserProfileId: (id) async {
        capturedId = id;
      },
    );

    service.setUserId('u-79001111111');
    expect(capturedId, 'u-79001111111');

    service.setUserId(null);
    expect(capturedId, isNull);
  });
}
