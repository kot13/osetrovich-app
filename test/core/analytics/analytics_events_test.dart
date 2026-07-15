import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/analytics/analytics_events.dart';

void main() {
  test('event names match analytics contract', () {
    expect(AnalyticsEvents.appLaunch, 'app_launch');
    expect(AnalyticsEvents.catalogView, 'catalog_view');
    expect(AnalyticsEvents.productView, 'product_view');
    expect(AnalyticsEvents.addToCart, 'add_to_cart');
    expect(AnalyticsEvents.checkoutStart, 'checkout_start');
    expect(AnalyticsEvents.orderSuccess, 'order_success');
  });

  test('product_view params include product_id', () {
    expect(AnalyticsEvents.productViewParams('p1'), {'product_id': 'p1'});
  });

  test('order_success params include order_id and order_total', () {
    expect(
      AnalyticsEvents.orderSuccessParams(orderId: 'ord-1', orderTotalRub: 2500),
      {'order_id': 'ord-1', 'order_total': 2500},
    );
  });
}
