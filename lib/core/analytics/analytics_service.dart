abstract class AnalyticsService {
  void reportAppLaunch();

  void reportCatalogView();

  void reportProductView(String productId);

  void reportAddToCart(String productId);

  void reportCheckoutStart();

  void reportOrderSuccess({
    required String orderId,
    required int orderTotalRub,
  });

  void setUserId(String? userId);

  Future<void> setPushEnabled(bool enabled);
}
