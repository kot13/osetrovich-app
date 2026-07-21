import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/widgets/loading_indicator.dart';
import 'package:osetrovich/features/cart/data/order_repository.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/home/domain/order_rating_error.dart';
import 'package:osetrovich/features/home/presentation/order_rating_sheet.dart';
import 'package:osetrovich/features/notifications/domain/notification_action.dart';
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
  var _isOpeningRating = false;
  var _ratingSubmitted = false;

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
    final currentOrderAsync = ref.watch(currentOrderProvider);

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
            return Center(
              child: Text(
                AppStrings.notificationUnavailable,
                style: TextStyle(color: AppColors.dark.withValues(alpha: 0.7)),
              ),
            );
          }

          final action = notificationActionFor(notification);
          final showRateButton =
              action == NotificationAction.rateOrder &&
              !_ratingSubmitted &&
              currentOrderAsync.maybeWhen(
                data: (order) => order?.ratingState == OrderRatingState.pending,
                orElse: () => false,
              );

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
                if (showRateButton) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.dark,
                    ),
                    onPressed: _isOpeningRating ? null : _onRateOrder,
                    child:
                        _isOpeningRating
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text(AppStrings.rateOrderFromNotification),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onRateOrder() async {
    setState(() => _isOpeningRating = true);
    try {
      final order = await ref.read(orderRepositoryProvider).getCurrentOrder();
      if (!mounted) {
        return;
      }
      if (order == null || order.ratingState != OrderRatingState.pending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.ratingUnavailable)),
        );
        return;
      }

      await showOrderRatingSheet(
        context,
        onSubmit: (stars, comment) async {
          try {
            await ref
                .read(orderRepositoryProvider)
                .submitOrderRating(
                  order.id,
                  SubmitOrderRatingRequest(stars: stars, comment: comment),
                );
            if (!mounted) {
              return;
            }
            setState(() => _ratingSubmitted = true);
            ref.invalidate(currentOrderProvider);
            showRatingThankYouSnackBar(context);
          } on ApiException catch (e) {
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(orderRatingErrorMessage(e))));
            if (shouldRefreshOrderAfterRatingError(e)) {
              ref.invalidate(currentOrderProvider);
            }
          }
        },
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(orderRatingErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _isOpeningRating = false);
      }
    }
  }
}
