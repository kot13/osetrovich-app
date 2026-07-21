import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';

void main() {
  test('mock notifications use real ids and API 0.10 texts', () async {
    final client = MockApiClient();
    await client.verifySmsCode('+79001234567', MockApiClient.validCode);

    final notifications = await client.getNotifications();
    final ids = notifications.map((item) => item.id).toSet();

    expect(ids.contains('n1'), isFalse);
    expect(ids.contains('n2'), isFalse);
    expect(ids, containsAll(['1', '2', '3', '4']));
    expect(notifications.any((item) => item.title == 'Заказ принят'), isTrue);
    expect(notifications.any((item) => item.body.contains('\n')), isTrue);
  });

  test('registerPushToken stores token for authorized user', () async {
    final client = MockApiClient();
    await client.verifySmsCode('+79001234567', MockApiClient.validCode);

    await client.registerPushToken(token: 'fcm-token', platform: 'android');

    expect(client.registeredPushToken, 'fcm-token');
    expect(client.registeredPushPlatform, 'android');
  });

  test('registerPushToken rejects empty token', () async {
    final client = MockApiClient();
    await client.verifySmsCode('+79001234567', MockApiClient.validCode);

    expect(
      () => client.registerPushToken(token: '', platform: 'android'),
      throwsA(isA<Exception>()),
    );
  });

  test('mark read and read-all update unread count', () async {
    final client = MockApiClient();
    await client.verifySmsCode('+79001234567', MockApiClient.validCode);

    final before = await client.getUnreadNotificationCount();
    expect(before.unreadCount, 3);

    await client.markNotificationRead('1');
    final afterOne = await client.getUnreadNotificationCount();
    expect(afterOne.unreadCount, 2);

    await client.markAllNotificationsRead();
    final afterAll = await client.getUnreadNotificationCount();
    expect(afterAll.unreadCount, 0);
  });
}
