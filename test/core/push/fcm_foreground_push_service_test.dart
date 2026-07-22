import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/push/fcm_foreground_push_service.dart';
import 'package:osetrovich/core/push/push_incoming_message.dart';

void main() {
  test('FirebaseFcmForegroundPushService maps onMessage to PushIncomingMessage',
      () async {
    final controller = StreamController<RemoteMessage>();
    final service = FirebaseFcmForegroundPushService(
      onMessageStream: () => controller.stream,
    );

    final messages = <PushIncomingMessage>[];
    final subscription = service.messages.listen(messages.add);

    service.start();
    controller.add(
      RemoteMessage(
        notification: const RemoteNotification(title: 'Тест', body: 'Тело'),
        data: const {
          'notification_id': '3',
          'deeplink': 'osetrovich://notifications/3',
        },
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(messages, hasLength(1));
    expect(messages.single.notificationId, '3');
    expect(messages.single.title, 'Тест');

    await subscription.cancel();
    service.dispose();
    await controller.close();
  });
}
