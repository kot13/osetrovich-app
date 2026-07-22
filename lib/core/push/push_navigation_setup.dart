import 'dart:async';

import 'package:appmetrica_push_plugin/appmetrica_push_plugin.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/analytics/analytics_bootstrap.dart';
import 'package:osetrovich/core/push/firebase_push_bootstrap.dart';
import 'package:osetrovich/core/push/push_providers.dart';
import 'package:osetrovich/core/push/push_tap_navigation.dart';

/// Подписка на открытие push (cold start + tap) и навигация по deep link.
final pushNavigationSetupProvider = Provider.family<void, GoRouter>((
  ref,
  router,
) {
  final handler = ref.watch(pushDeeplinkHandlerProvider);
  final subscriptions = <StreamSubscription<dynamic>>[];

  if (FirebasePushBootstrap.isFcmAvailable) {
    subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        navigateFromFcmMessage(handler, router, ref, message);
      }),
    );

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((message) {
          if (message != null) {
            navigateFromFcmMessage(handler, router, ref, message);
          }
        })
        .catchError((Object error, StackTrace stack) {
          if (kDebugMode) {
            debugPrint('FCM launch push info: $error');
          }
        });
  }

  if (!AnalyticsBootstrap.isPushEnabled) {
    ref.onDispose(() {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    });
    return;
  }

  subscriptions.add(
    AppMetricaPush.pushClickStream.listen((info) {
      navigateFromPushPayloadString(handler, router, ref, info.payload);
    }),
  );

  AppMetricaPush.getLaunchPushInfo()
      .then((info) {
        navigateFromPushPayloadString(handler, router, ref, info.payload);
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
