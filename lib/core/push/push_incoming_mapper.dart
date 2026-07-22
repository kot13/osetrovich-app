import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:osetrovich/core/push/push_incoming_message.dart';

/// Парсинг FCM / AppMetrica payload → [PushIncomingMessage].
class PushIncomingMapper {
  const PushIncomingMapper._();

  static PushIncomingMessage fromFcm(RemoteMessage message) {
    return fromDataMap(
      data: message.data.map((key, value) => MapEntry(key, value.toString())),
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }

  static PushIncomingMessage fromPayloadString(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return const PushIncomingMessage();
    }

    final trimmed = payload.trim();
    if (trimmed.startsWith('osetrovich://')) {
      return PushIncomingMessage(deeplink: trimmed);
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return fromJsonMap(decoded);
      }
    } on Object {
      // fall through
    }

    return const PushIncomingMessage();
  }

  static PushIncomingMessage fromJsonMap(Map<String, dynamic> json) {
    final data = <String, String>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (value != null) {
        data[entry.key] = value.toString();
      }
    }
    return fromDataMap(data: data);
  }

  static PushIncomingMessage fromDataMap({
    required Map<String, String> data,
    String? title,
    String? body,
  }) {
    final deeplink = _nonEmpty(data['deeplink']) ?? _nonEmpty(data['url']);
    final notificationId = _nonEmpty(data['notification_id']);

    return PushIncomingMessage(
      title: title,
      body: body,
      deeplink: deeplink,
      notificationId: notificationId,
    );
  }

  static String? _nonEmpty(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }
}
