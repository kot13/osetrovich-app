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
      handler.resolveRoute({'type': 'notification', 'targetId': 'n-7'}),
      '/home/notifications/n-7',
    );
  });

  test('resolves product deep link', () {
    expect(
      handler.resolveRoute({'type': 'product', 'targetId': 'p1'}),
      '/catalog/product/p1',
    );
  });

  test('falls back to home for unknown type', () {
    expect(handler.resolveRoute({'type': 'unknown'}), '/home');
  });

  test('falls back to home when targetId missing for promotion', () {
    expect(handler.resolveRoute({'type': 'promotion'}), '/home');
  });

  test('parses JSON payload string', () {
    expect(
      handler.resolveRouteFromPayloadString(
        '{"type":"order","targetId":"ord-1"}',
      ),
      '/home',
    );
  });
}
