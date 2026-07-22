import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/push/push_incoming_mapper.dart';

void main() {
  group('push tap navigation payload guard', () {
    test('null AppMetrica payload has no navigation target', () {
      final message = PushIncomingMapper.fromPayloadString(null);
      expect(message.toNavigationPayload(), isNull);
      expect(message.hasNavigationTarget, isFalse);
    });

    test('empty JSON AppMetrica payload has no navigation target', () {
      final message = PushIncomingMapper.fromPayloadString('{}');
      expect(message.toNavigationPayload(), isNull);
      expect(message.hasNavigationTarget, isFalse);
    });

    test('order push payload has navigation target', () {
      final message = PushIncomingMapper.fromPayloadString(
        '{"deeplink":"osetrovich://notifications/42","notification_id":"42"}',
      );
      expect(message.toNavigationPayload(), 'osetrovich://notifications/42');
      expect(message.hasNavigationTarget, isTrue);
    });
  });
}
