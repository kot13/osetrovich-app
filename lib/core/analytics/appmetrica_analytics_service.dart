import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:osetrovich/core/analytics/analytics_events.dart';
import 'package:osetrovich/core/analytics/analytics_service.dart';

typedef AnalyticsEventSender =
    Future<void> Function(String eventName, Map<String, Object>? attributes);

typedef AnalyticsUserIdSetter = Future<void> Function(String? userId);

typedef AnalyticsUserProfileReporter =
    Future<void> Function(AppMetricaUserProfile profile);

class AppMetricaAnalyticsService implements AnalyticsService {
  AppMetricaAnalyticsService({
    AnalyticsEventSender? sendEvent,
    AnalyticsUserIdSetter? setUserProfileId,
    AnalyticsUserProfileReporter? reportUserProfile,
  }) : _sendEvent =
           sendEvent ??
           ((name, attrs) => AppMetrica.reportEventWithMap(name, attrs)),
       _setUserProfileId =
           setUserProfileId ?? ((id) => AppMetrica.setUserProfileID(id)),
       _reportUserProfile =
           reportUserProfile ??
           ((profile) => AppMetrica.reportUserProfile(profile));

  final AnalyticsEventSender _sendEvent;
  final AnalyticsUserIdSetter _setUserProfileId;
  final AnalyticsUserProfileReporter _reportUserProfile;

  @override
  void reportAppLaunch() {
    _sendEvent(AnalyticsEvents.appLaunch, null);
  }

  @override
  void reportCatalogView() {
    _sendEvent(AnalyticsEvents.catalogView, null);
  }

  @override
  void reportProductView(String productId) {
    _sendEvent(
      AnalyticsEvents.productView,
      AnalyticsEvents.productViewParams(productId),
    );
  }

  @override
  void reportAddToCart(String productId) {
    _sendEvent(
      AnalyticsEvents.addToCart,
      AnalyticsEvents.addToCartParams(productId),
    );
  }

  @override
  void reportCheckoutStart() {
    _sendEvent(AnalyticsEvents.checkoutStart, null);
  }

  @override
  void reportOrderSuccess({
    required String orderId,
    required int orderTotalRub,
  }) {
    _sendEvent(
      AnalyticsEvents.orderSuccess,
      AnalyticsEvents.orderSuccessParams(
        orderId: orderId,
        orderTotalRub: orderTotalRub,
      ),
    );
  }

  @override
  void setUserId(String? userId) {
    _setUserProfileId(userId);
  }

  @override
  Future<void> setPushEnabled(bool enabled) {
    return _reportUserProfile(
      AppMetricaUserProfile([
        AppMetricaBooleanAttribute.withValue(
          AnalyticsEvents.pushEnabledAttribute,
          enabled,
        ),
        AppMetricaNotificationEnabledAttribute.withValue(enabled),
      ]),
    );
  }
}
