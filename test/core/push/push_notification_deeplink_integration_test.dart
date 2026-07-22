import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/push/push_deeplink_handler.dart';
import 'package:osetrovich/core/push/push_incoming_mapper.dart';

void main() {
  group('Push notification deeplink flow', () {
    const handler = PushDeeplinkHandler();

    test('order push payload opens notification detail route', () {
      final message = PushIncomingMapper.fromPayloadString(
        '{"deeplink":"osetrovich://notifications/1","notification_id":"1"}',
      );

      expect(
        handler.resolveRouteFromPayloadString(message.toNavigationPayload()),
        '/home/notifications/1',
      );
    });

    test('notification_id only payload opens detail route', () {
      final message = PushIncomingMapper.fromPayloadString(
        '{"notification_id":"2"}',
      );

      expect(
        handler.resolveRouteFromPayloadString(message.toNavigationPayload()),
        '/home/notifications/2',
      );
    });

    test('raw deeplink payload opens notification detail', () {
      expect(
        handler.resolveRouteFromPayloadString(
          'osetrovich://notifications/3',
        ),
        '/home/notifications/3',
      );
    });
  });
}
