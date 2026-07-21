import 'dart:async';

import 'package:appmetrica_push_plugin/appmetrica_push_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/analytics/analytics_bootstrap.dart';
import 'package:osetrovich/core/push/push_providers.dart';

/// Подписка на открытие push (cold start + tap) и навигация по deep link.
final pushNavigationSetupProvider = Provider.family<void, GoRouter>((
  ref,
  router,
) {
  if (!AnalyticsBootstrap.isPushEnabled) {
    return;
  }

  final handler = ref.watch(pushDeeplinkHandlerProvider);
  final subscriptions = <StreamSubscription<dynamic>>[];

  subscriptions.add(
    AppMetricaPush.pushClickStream.listen((info) {
      handler.navigate(router, ref, info.payload);
    }),
  );

  AppMetricaPush.getLaunchPushInfo()
      .then((info) {
        if (info.payload != null && info.payload!.isNotEmpty) {
          handler.navigate(router, ref, info.payload);
        }
      })
      .catchError((Object error, StackTrace stack) {
        if (kDebugMode) {
          debugPrint('AppMetrica launch push info: $error');
        }
      });

  ref.onDispose(() {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  });
});
