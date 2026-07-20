import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/features/notifications/domain/app_notification.dart';

enum NotificationAction { none, rateOrder }

NotificationAction notificationActionFor(AppNotification notification) {
  if (notification.title == AppStrings.orderDeliveredNotificationTitle) {
    return NotificationAction.rateOrder;
  }
  return NotificationAction.none;
}

String notificationPreviewLine(String body) {
  final lines = body.split('\n');
  return lines.first.trim();
}
