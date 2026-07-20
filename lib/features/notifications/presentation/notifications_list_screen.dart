import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/widgets/empty_state.dart';
import 'package:osetrovich/core/widgets/loading_indicator.dart';
import 'package:osetrovich/features/notifications/domain/app_notification.dart';
import 'package:osetrovich/features/notifications/domain/notification_action.dart';
import 'package:osetrovich/features/notifications/domain/notifications_notifier.dart';

class NotificationsListScreen extends ConsumerWidget {
  const NotificationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsNotifierProvider);
    final hasUnread = ref.watch(hasUnreadNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notificationsTitle),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton:
          hasUnread
              ? FloatingActionButton.extended(
                onPressed:
                    () =>
                        ref
                            .read(notificationsNotifierProvider.notifier)
                            .markAllRead(),
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.dark,
                icon: const Icon(Icons.done_all),
                label: const Text(AppStrings.markAllRead),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: notificationsAsync.when(
        loading: () => const LoadingIndicator(),
        error:
            (_, __) => EmptyState(
              message: AppStrings.requestFailed,
              actionLabel: AppStrings.retry,
              onAction:
                  () =>
                      ref.read(notificationsNotifierProvider.notifier).reload(),
            ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(message: AppStrings.notificationsEmpty);
          }

          return ListView.separated(
            padding: EdgeInsets.only(bottom: hasUnread ? 88 : 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = items[index];
              return _NotificationListTile(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationListTile extends StatelessWidget {
  const _NotificationListTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/home/notifications/${notification.id}'),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
          color:
              notification.isRead
                  ? AppColors.dark.withValues(alpha: 0.6)
                  : AppColors.dark,
        ),
      ),
      subtitle: Text(
        notificationPreviewLine(notification.body),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color:
              notification.isRead
                  ? AppColors.dark.withValues(alpha: 0.5)
                  : AppColors.dark,
        ),
      ),
      trailing:
          notification.isRead
              ? null
              : Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
    );
  }
}

String formatNotificationDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.$year $hour:$minute';
}
