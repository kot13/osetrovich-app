import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/loading_indicator.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/data/order_repository.dart';
import 'package:osetrovich/features/home/data/home_repository.dart';
import 'package:osetrovich/features/home/domain/home_profile_slot_ui_state.dart';
import 'package:osetrovich/features/home/presentation/banner_carousel.dart';
import 'package:osetrovich/features/home/presentation/home_order_history_section.dart';
import 'package:osetrovich/features/home/presentation/home_lemon_gamification_card.dart';
import 'package:osetrovich/features/home/presentation/home_profile_slot.dart';
import 'package:osetrovich/features/home/domain/home_lemon_gamification_ui_model.dart';
import 'package:osetrovich/features/home/presentation/home_weekly_products_section.dart';
import 'package:osetrovich/features/notifications/domain/notifications_notifier.dart';
import 'package:osetrovich/features/notifications/presentation/widgets/notification_bell_action.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationsNotifierProvider);
    final bannersAsync = ref.watch(bannersProvider);
    final currentOrderAsync = ref.watch(currentOrderProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final profileAsync =
        isAuthenticated ? ref.watch(profileNotifierProvider) : null;
    final profileSlotState = buildHomeProfileSlotUiState(
      isAuthenticated: isAuthenticated,
      profile: profileAsync ?? const AsyncData(null),
    );

    final showOrderSection =
        isAuthenticated &&
        currentOrderAsync.maybeWhen(
          data: (order) => order != null,
          orElse: () => false,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tabHome),
        actions: const [NotificationBellAction()],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshHome(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: bannersAsync.when(
                loading:
                    () => LayoutBuilder(
                      builder:
                          (context, constraints) => SizedBox(
                            height: bannerCarouselHeightForWidth(
                              constraints.maxWidth,
                              2,
                            ),
                            child: const LoadingIndicator(),
                          ),
                    ),
                error:
                    (_, __) => _HomeSectionError(
                      onRetry: () => ref.invalidate(bannersProvider),
                    ),
                data: (banners) => BannerCarousel(banners: banners),
              ),
            ),
            HomeProfileSlot(
              mode: profileSlotState.mode,
              profile: profileSlotState.profile,
            ),
            if (isAuthenticated &&
                profileAsync != null &&
                profileAsync.hasValue &&
                !profileAsync.hasError &&
                profileAsync.requireValue != null)
              HomeLemonGamificationCard(
                model: buildHomeLemonGamificationUiModel(
                  profileAsync.requireValue!.lemons,
                ),
              ),
            Padding(
              padding: EdgeInsets.only(bottom: showOrderSection ? 0 : 16),
              child: const HomeWeeklyProductsSection(),
            ),
            if (isAuthenticated)
              currentOrderAsync.when(
                loading: () => const SizedBox.shrink(),
                error:
                    (_, __) => _HomeSectionError(
                      onRetry: () => ref.invalidate(currentOrderProvider),
                    ),
                data: (order) {
                  if (order == null) {
                    return const SizedBox.shrink();
                  }
                  return HomeOrderHistorySection(
                    key: ValueKey(order.id),
                    order: order,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _refreshHome(WidgetRef ref) async {
  ref.invalidate(bannersProvider);
  ref.invalidate(weeklyProductsProvider);

  final refreshTasks = <Future<Object?>>[
    ref.read(bannersProvider.future),
    ref.read(weeklyProductsProvider.future),
  ];

  if (ref.read(isAuthenticatedProvider)) {
    ref.invalidate(currentOrderProvider);
    refreshTasks.add(ref.read(currentOrderProvider.future));
    refreshTasks.add(ref.read(unreadCountNotifierProvider.notifier).refresh());
    refreshTasks.add(ref.read(notificationsNotifierProvider.notifier).reload());
    refreshTasks.add(ref.read(profileNotifierProvider.notifier).refresh());
  }

  await Future.wait(refreshTasks);
}

class _HomeSectionError extends StatelessWidget {
  const _HomeSectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.homeLoadError,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(AppStrings.homeRetry),
          ),
        ],
      ),
    );
  }
}
