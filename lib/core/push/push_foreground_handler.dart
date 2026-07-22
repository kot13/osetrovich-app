import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/widgets/root_scaffold_messenger.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/push/firebase_push_bootstrap.dart';
import 'package:osetrovich/core/push/push_incoming_message.dart';
import 'package:osetrovich/core/push/push_providers.dart';
import 'package:osetrovich/core/router/app_router.dart';
import 'package:osetrovich/features/notifications/domain/notifications_notifier.dart';

class PushForegroundHandler {
  PushForegroundHandler({
    required Stream<PushIncomingMessage> receiveStream,
    required void Function() refreshNotifications,
    required void Function(PushIncomingMessage message) showBanner,
    required void Function(PushIncomingMessage message) onBannerTap,
  }) : _receiveStream = receiveStream,
       _refreshNotifications = refreshNotifications,
       _showBanner = showBanner,
       _onBannerTap = onBannerTap;

  final Stream<PushIncomingMessage> _receiveStream;
  final void Function() _refreshNotifications;
  final void Function(PushIncomingMessage message) _showBanner;
  final void Function(PushIncomingMessage message) _onBannerTap;
  StreamSubscription<PushIncomingMessage>? _subscription;

  void start() {
    _subscription ??= _receiveStream.listen((message) {
      _refreshNotifications();
      _showBanner(message);
    });
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  void handleBannerTap(PushIncomingMessage message) {
    _onBannerTap(message);
  }
}

void showPushSnackBar(
  PushIncomingMessage message, {
  required void Function(PushIncomingMessage message) onTap,
}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) {
    return;
  }

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(_pushSnackBarText(message)),
      action:
          message.hasNavigationTarget
              ? SnackBarAction(
                label: AppStrings.pushNotificationOpen,
                onPressed: () => onTap(message),
              )
              : null,
    ),
  );
}

String _pushSnackBarText(PushIncomingMessage message) {
  final title = message.title?.trim();
  final body = message.body?.trim();
  final hasTitle = title != null && title.isNotEmpty;
  final hasBody = body != null && body.isNotEmpty;

  if (hasTitle && hasBody) {
    return '$title: $body';
  }
  if (hasBody) {
    return body;
  }
  if (hasTitle) {
    return title;
  }
  return AppStrings.pushNotificationReceived;
}

final pushForegroundSetupProvider = Provider<void>((ref) {
  if (!FirebasePushBootstrap.isFcmAvailable) {
    return;
  }

  final fcmService = ref.watch(fcmForegroundPushServiceProvider);
  fcmService.start();

  final router = ref.watch(routerProvider);
  final handler = PushForegroundHandler(
    receiveStream: fcmService.messages,
    refreshNotifications: () {
      ref.read(unreadCountNotifierProvider.notifier).refresh();
      ref.read(notificationsNotifierProvider.notifier).reload();
    },
    showBanner: (message) {
      showPushSnackBar(
        message,
        onTap: (tapMessage) {
          ref.read(pushDeeplinkHandlerProvider).navigate(
            router,
            ref,
            tapMessage.toNavigationPayload(),
          );
        },
      );
    },
    onBannerTap: (message) {
      ref.read(pushDeeplinkHandlerProvider).navigate(
        router,
        ref,
        message.toNavigationPayload(),
      );
    },
  );
  handler.start();

  ref.onDispose(() {
    handler.dispose();
    fcmService.dispose();
  });
});
