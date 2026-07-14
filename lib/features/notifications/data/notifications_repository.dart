import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/notifications/domain/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AppNotification>> getNotifications() =>
      _apiClient.getNotifications();

  Future<AppNotification> getNotificationById(String id) =>
      _apiClient.getNotificationById(id);

  Future<void> markRead(String id) => _apiClient.markNotificationRead(id);

  Future<void> markAllRead() => _apiClient.markAllNotificationsRead();
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});
