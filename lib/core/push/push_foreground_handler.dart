import 'dart:async';

import 'package:appmetrica_push_plugin/appmetrica_push_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/analytics/analytics_bootstrap.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/features/notifications/domain/notifications_notifier.dart';

typedef PushReceiveStream = Stream<void> Function();

class PushForegroundHandler {
  PushForegroundHandler({
    PushReceiveStream? receiveStream,
    required void Function(String message) showMessage,
    required void Function() refreshNotifications,
  }) : _receiveStream =
           receiveStream ??
           (() => AppMetricaPush.pushClickStream.map((_) {})),
       _showMessage = showMessage,
       _refreshNotifications = refreshNotifications;

  final PushReceiveStream _receiveStream;
  final void Function(String message) _showMessage;
  final void Function() _refreshNotifications;
  StreamSubscription<void>? _subscription;

  void start() {
    _subscription ??= _receiveStream().listen((_) {
      _refreshNotifications();
      _showMessage(AppStrings.pushNotificationReceived);
    });
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

final pushForegroundSetupProvider = Provider<void>((ref) {
  if (!AnalyticsBootstrap.isPushEnabled) {
    return;
  }
  final handler = PushForegroundHandler(
    showMessage: (_) {},
    refreshNotifications: () {
      ref.invalidate(unreadCountNotifierProvider);
      ref.read(notificationsNotifierProvider.notifier).reload();
    },
  );
  handler.start();
  ref.onDispose(handler.dispose);
});
