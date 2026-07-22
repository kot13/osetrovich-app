import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/push/push_incoming_mapper.dart';

void main() {
  group('PushIncomingMapper', () {
    test('fromFcm maps notification and data fields', () {
      final message = RemoteMessage(
        notification: const RemoteNotification(
          title: 'Заказ принят',
          body: 'Текст уведомления',
        ),
        data: const {
          'deeplink': 'osetrovich://notifications/42',
          'notification_id': '42',
        },
      );

      final result = PushIncomingMapper.fromFcm(message);

      expect(result.title, 'Заказ принят');
      expect(result.body, 'Текст уведомления');
      expect(result.deeplink, 'osetrovich://notifications/42');
      expect(result.notificationId, '42');
      expect(result.toNavigationPayload(), 'osetrovich://notifications/42');
    });

    test('fromPayloadString parses raw deeplink', () {
      final result = PushIncomingMapper.fromPayloadString(
        'osetrovich://notifications/7',
      );

      expect(result.deeplink, 'osetrovich://notifications/7');
      expect(result.toNavigationPayload(), 'osetrovich://notifications/7');
    });

    test('fromPayloadString parses JSON order push', () {
      final result = PushIncomingMapper.fromPayloadString(
        '{"deeplink":"osetrovich://notifications/42","notification_id":"42"}',
      );

      expect(result.deeplink, 'osetrovich://notifications/42');
      expect(result.notificationId, '42');
    });

    test('fromPayloadString builds navigation from notification_id only', () {
      final result = PushIncomingMapper.fromPayloadString(
        '{"notification_id":"99"}',
      );

      expect(result.deeplink, isNull);
      expect(result.notificationId, '99');
      expect(result.toNavigationPayload(), 'osetrovich://notifications/99');
    });

    test('fromPayloadString returns empty message for null payload', () {
      final result = PushIncomingMapper.fromPayloadString(null);

      expect(result.title, isNull);
      expect(result.toNavigationPayload(), isNull);
    });

    test('fromPayloadString parses AppMetrica tap JSON payload', () {
      final result = PushIncomingMapper.fromPayloadString(
        '{"deeplink":"osetrovich://notifications/5","notification_id":"5","type":"notification"}',
      );

      expect(result.toNavigationPayload(), 'osetrovich://notifications/5');
    });
  });
}
