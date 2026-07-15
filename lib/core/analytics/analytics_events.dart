/// Имена и параметры событий воронки (контракт analytics-events.yaml).
abstract final class AnalyticsEvents {
  static const appLaunch = 'app_launch';
  static const catalogView = 'catalog_view';
  static const productView = 'product_view';
  static const addToCart = 'add_to_cart';
  static const checkoutStart = 'checkout_start';
  static const orderSuccess = 'order_success';

  static const productId = 'product_id';
  static const orderId = 'order_id';
  static const orderTotal = 'order_total';

  static const pushEnabledAttribute = 'push_enabled';

  static Map<String, Object> productViewParams(String productId) {
    return {AnalyticsEvents.productId: productId};
  }

  static Map<String, Object> addToCartParams(String productId) {
    return {AnalyticsEvents.productId: productId};
  }

  static Map<String, Object> orderSuccessParams({
    required String orderId,
    required int orderTotalRub,
  }) {
    return {
      AnalyticsEvents.orderId: orderId,
      AnalyticsEvents.orderTotal: orderTotalRub,
    };
  }
}
