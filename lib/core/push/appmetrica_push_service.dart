import 'package:appmetrica_push_plugin/appmetrica_push_plugin.dart';
import 'package:osetrovich/core/analytics/analytics_service.dart';
import 'package:osetrovich/core/push/push_service.dart';

typedef PushEnabledSync = Future<void> Function(bool enabled);

class AppMetricaPushService implements PushService {
  AppMetricaPushService(
    AnalyticsService analytics, {
    PushEnabledSync? syncPushEnabledToAnalytics,
    void Function(void Function(Map<String, String?>) listener)?
    tokenStreamBinder,
    Future<Map<String, String?>> Function()? tokenReader,
  }) : _syncPushEnabledToAnalytics =
           syncPushEnabledToAnalytics ?? analytics.setPushEnabled,
       _tokenStreamBinder =
           tokenStreamBinder ??
           ((listener) {
             AppMetricaPush.tokenStream.listen(listener);
           }),
       _tokenReader = tokenReader ?? AppMetricaPush.getTokens;

  final PushEnabledSync _syncPushEnabledToAnalytics;
  final void Function(void Function(Map<String, String?>) listener)
  _tokenStreamBinder;
  final Future<Map<String, String?>> Function() _tokenReader;

  @override
  void listenForTokenUpdates(
    void Function(Map<String, String?> tokens) onTokens,
  ) {
    _tokenStreamBinder(onTokens);
  }

  @override
  Future<void> syncPushEnabled(bool enabled) {
    return _syncPushEnabledToAnalytics(enabled);
  }

  @override
  Future<Map<String, String?>> getTokens() => _tokenReader();
}
