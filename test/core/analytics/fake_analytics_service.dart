import 'package:osetrovich/core/analytics/analytics_events.dart';
import 'package:osetrovich/core/analytics/analytics_service.dart';

class FakeAnalyticsService implements AnalyticsService {
  final List<String> events = [];
  final List<Map<String, Object>> eventParams = [];
  String? userId;
  bool? pushEnabled;

  @override
  void reportAddToCart(String productId) {
    events.add(AnalyticsEvents.addToCart);
    eventParams.add(AnalyticsEvents.addToCartParams(productId));
  }

  @override
  void reportAppLaunch() {
    events.add(AnalyticsEvents.appLaunch);
    eventParams.add({});
  }

  @override
  void reportCatalogView() {
    events.add(AnalyticsEvents.catalogView);
    eventParams.add({});
  }

  @override
  void reportCheckoutStart() {
    events.add(AnalyticsEvents.checkoutStart);
    eventParams.add({});
  }

  @override
  void reportOrderSuccess({
    required String orderId,
    required int orderTotalRub,
  }) {
    events.add(AnalyticsEvents.orderSuccess);
    eventParams.add(
      AnalyticsEvents.orderSuccessParams(
        orderId: orderId,
        orderTotalRub: orderTotalRub,
      ),
    );
  }

  @override
  void reportProductView(String productId) {
    events.add(AnalyticsEvents.productView);
    eventParams.add(AnalyticsEvents.productViewParams(productId));
  }

  @override
  void setUserId(String? userId) {
    this.userId = userId;
  }

  @override
  Future<void> setPushEnabled(bool enabled) async {
    pushEnabled = enabled;
  }
}
