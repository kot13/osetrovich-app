import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/push/push_deeplink_handler.dart';

void main() {
  const handler = PushDeeplinkHandler();

  test('resolves promotion deep link', () {
    expect(
      handler.resolveRoute({'type': 'promotion', 'targetId': 'promo-1'}),
      '/promotions/article/promo-1',
    );
  });

  test('resolves notification deep link', () {
    expect(
      handler.resolveRoute({'type': 'notification', 'targetId': '7'}),
      '/home/notifications/7',
    );
  });

  test('resolves product deep link', () {
    expect(
      handler.resolveRoute({'type': 'product', 'targetId': 'p1'}),
      '/catalog/product/p1',
    );
  });

  test('falls back to notifications list for unknown type', () {
    expect(handler.resolveRoute({'type': 'unknown'}), '/home/notifications');
  });

  test('falls back to notifications list when type missing', () {
    expect(handler.resolveRoute({}), '/home/notifications');
  });

  test('parses JSON payload string', () {
    expect(
      handler.resolveRouteFromPayloadString(
        '{"type":"order","targetId":"ord-1"}',
      ),
      '/home',
    );
  });

  test('empty payload opens notifications list', () {
    expect(handler.resolveRouteFromPayloadString(null), '/home/notifications');
    expect(handler.resolveRouteFromPayloadString(''), '/home/notifications');
  });

  test('raw osetrovich URL', () {
    expect(
      handler.resolveRouteFromPayloadString('osetrovich://catalog/product/1000'),
      '/catalog/product/1000',
    );
  });

  test('JSON deeplink field has priority over type', () {
    expect(
      handler.resolveRouteFromPayloadString(
        '{"deeplink":"osetrovich://profile","type":"home"}',
      ),
      '/profile',
    );
  });

  test('JSON url field resolves deeplink', () {
    expect(
      handler.resolveRouteFromPayloadString(
        '{"url":"osetrovich://promotions"}',
      ),
      '/promotions',
    );
  });

  test('JSON notification_id resolves notification detail', () {
    expect(
      handler.resolveRoute({'notification_id': '42'}),
      '/home/notifications/42',
    );
  });

  test('deeplink has priority over notification_id', () {
    expect(
      handler.resolveRoute({
        'deeplink': 'osetrovich://notifications/1',
        'notification_id': '2',
      }),
      '/home/notifications/1',
    );
  });

  test('order push JSON resolves detail route', () {
    expect(
      handler.resolveRouteFromPayloadString(
        '{"deeplink":"osetrovich://notifications/42","notification_id":"42"}',
      ),
      '/home/notifications/42',
    );
  });
}
