import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/analytics/analytics_bootstrap.dart';
import 'package:osetrovich/core/analytics/analytics_providers.dart';
import 'package:osetrovich/core/push/appmetrica_push_service.dart';
import 'package:osetrovich/core/push/fcm_foreground_push_service.dart';
import 'package:osetrovich/core/push/firebase_push_bootstrap.dart';
import 'package:osetrovich/core/push/no_op_push_service.dart';
import 'package:osetrovich/core/push/push_deeplink_handler.dart';
import 'package:osetrovich/core/push/push_service.dart';

final pushDeeplinkHandlerProvider = Provider<PushDeeplinkHandler>(
  (ref) => const PushDeeplinkHandler(),
);

final pushServiceProvider = Provider<PushService>((ref) {
  if (!AnalyticsBootstrap.isPushEnabled) {
    return NoOpPushService();
  }
  return AppMetricaPushService(ref.watch(analyticsServiceProvider));
});

final fcmForegroundPushServiceProvider = Provider<FcmForegroundPushService>((
  ref,
) {
  if (!FirebasePushBootstrap.isFcmAvailable) {
    return NoOpFcmForegroundPushService();
  }
  return FirebaseFcmForegroundPushService();
});
