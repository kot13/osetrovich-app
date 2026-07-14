import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/features/notifications/data/notifications_repository.dart';
import 'package:osetrovich/features/notifications/domain/app_notification.dart';

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    return ref.read(notificationsRepositoryProvider).getNotifications();
  }

  Future<void> markRead(String id) async {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final notification = current.where((n) => n.id == id).firstOrNull;
    if (notification == null || notification.isRead) {
      return;
    }

    await ref.read(notificationsRepositoryProvider).markRead(id);
    state = AsyncData(
      await ref.read(notificationsRepositoryProvider).getNotifications(),
    );
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null || !current.any((n) => !n.isRead)) {
      return;
    }

    await ref.read(notificationsRepositoryProvider).markAllRead();
    state = AsyncData(
      await ref.read(notificationsRepositoryProvider).getNotifications(),
    );
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(
      await ref.read(notificationsRepositoryProvider).getNotifications(),
    );
  }
}

final notificationsNotifierProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
      NotificationsNotifier.new,
    );

final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsNotifierProvider);
  return notifications.when(
    data: (items) => items.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(unreadCountProvider) > 0;
});
