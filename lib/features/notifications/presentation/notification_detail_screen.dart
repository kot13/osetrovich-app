import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/widgets/loading_indicator.dart';
import 'package:osetrovich/features/notifications/domain/notifications_notifier.dart';
import 'package:osetrovich/features/notifications/presentation/notifications_list_screen.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  const NotificationDetailScreen({super.key, required this.notificationId});

  final String notificationId;

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  var _markedRead = false;

  @override
  Widget build(BuildContext context) {
    if (!_markedRead) {
      _markedRead = true;
      Future.microtask(() {
        if (!mounted) {
          return;
        }
        ref
            .read(notificationsNotifierProvider.notifier)
            .markRead(widget.notificationId);
      });
    }

    final notificationsAsync = ref.watch(notificationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (_, __) => const Center(child: Text(AppStrings.requestFailed)),
        data: (items) {
          final notification =
              items.where((n) => n.id == widget.notificationId).firstOrNull;
          if (notification == null) {
            return const Center(child: Text(AppStrings.requestFailed));
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  formatNotificationDateTime(notification.createdAt),
                  style: TextStyle(
                    color: AppColors.dark.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  notification.body,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
