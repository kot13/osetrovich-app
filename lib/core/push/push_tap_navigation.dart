import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/push/push_deeplink_handler.dart';
import 'package:osetrovich/core/push/push_incoming_mapper.dart';
import 'package:osetrovich/core/push/push_incoming_message.dart';

/// Навигация по tap на push только при наличии deeplink / notification_id.
void navigateFromPushTap(
  PushDeeplinkHandler handler,
  GoRouter router,
  Ref ref,
  PushIncomingMessage message, {
  bool postFrame = true,
}) {
  final payload = message.toNavigationPayload();
  if (payload == null) {
    return;
  }

  void navigate() => handler.navigate(router, ref, payload);
  if (postFrame) {
    WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
  } else {
    navigate();
  }
}

void navigateFromPushPayloadString(
  PushDeeplinkHandler handler,
  GoRouter router,
  Ref ref,
  String? rawPayload, {
  bool postFrame = true,
}) {
  navigateFromPushTap(
    handler,
    router,
    ref,
    PushIncomingMapper.fromPayloadString(rawPayload),
    postFrame: postFrame,
  );
}

void navigateFromFcmMessage(
  PushDeeplinkHandler handler,
  GoRouter router,
  Ref ref,
  RemoteMessage message, {
  bool postFrame = true,
}) {
  navigateFromPushTap(
    handler,
    router,
    ref,
    PushIncomingMapper.fromFcm(message),
    postFrame: postFrame,
  );
}
