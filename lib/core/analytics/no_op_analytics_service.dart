import 'package:osetrovich/core/analytics/analytics_service.dart';

class NoOpAnalyticsService implements AnalyticsService {
  @override
  void reportAddToCart(String productId) {}

  @override
  void reportAppLaunch() {}

  @override
  void reportCatalogView() {}

  @override
  void reportCheckoutStart() {}

  @override
  void reportOrderSuccess({
    required String orderId,
    required int orderTotalRub,
  }) {}

  @override
  void reportProductView(String productId) {}

  @override
  void setUserId(String? userId) {}

  @override
  Future<void> setPushEnabled(bool enabled) async {}
}
