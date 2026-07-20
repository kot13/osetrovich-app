import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/notifications/data/notifications_repository.dart';
import 'package:osetrovich/features/notifications/domain/app_notification.dart';
import 'package:osetrovich/features/notifications/domain/unread_count_notifier.dart';

export 'package:osetrovich/features/notifications/domain/unread_count_notifier.dart';

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    ref.listen<AuthSession?>(authSessionProvider, (previous, next) {
      if (next == null) {
        state = const AsyncData([]);
      } else if (previous == null) {
        ref.invalidateSelf();
      }
    });

    if (ref.read(authSessionProvider) == null) {
      return [];
    }

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

    try {
      await ref.read(notificationsRepositoryProvider).markRead(id);
    } on ApiException catch (error) {
      if (error.code == 'NOT_FOUND' || error.code == 'HTTP_404') {
        await reload();
        return;
      }
      rethrow;
    }

    await _refreshAfterMutation();
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null || !current.any((n) => !n.isRead)) {
      return;
    }

    await ref.read(notificationsRepositoryProvider).markAllRead();
    await _refreshAfterMutation();
  }

  Future<void> reload() async {
    if (ref.read(authSessionProvider) == null) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = AsyncData(
      await ref.read(notificationsRepositoryProvider).getNotifications(),
    );
  }

  Future<void> _refreshAfterMutation() async {
    state = AsyncData(
      await ref.read(notificationsRepositoryProvider).getNotifications(),
    );
    await ref.read(unreadCountNotifierProvider.notifier).refresh();
  }
}

final notificationsNotifierProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
      NotificationsNotifier.new,
    );
