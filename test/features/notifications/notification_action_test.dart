import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/features/notifications/domain/app_notification.dart';
import 'package:osetrovich/features/notifications/domain/notification_action.dart';

void main() {
  test('rateOrder only for delivered title', () {
    final delivered = AppNotification(
      id: '4',
      title: AppStrings.orderDeliveredNotificationTitle,
      body: 'text',
      createdAt: DateTime.utc(2026, 7, 10),
      isRead: true,
    );
    final accepted = AppNotification(
      id: '1',
      title: 'Заказ принят',
      body: 'text',
      createdAt: DateTime.utc(2026, 7, 10),
      isRead: false,
    );

    expect(notificationActionFor(delivered), NotificationAction.rateOrder);
    expect(notificationActionFor(accepted), NotificationAction.none);
  });

  test('notificationPreviewLine uses first line', () {
    expect(notificationPreviewLine('Line 1\nLine 2'), 'Line 1');
  });
}
