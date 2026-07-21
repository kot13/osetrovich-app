import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/loading_indicator.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/data/order_repository.dart';
import 'package:osetrovich/features/home/data/home_repository.dart';
import 'package:osetrovich/features/home/domain/home_profile_slot_ui_state.dart';
import 'package:osetrovich/features/home/presentation/banner_carousel.dart';
import 'package:osetrovich/features/home/presentation/home_order_history_section.dart';
import 'package:osetrovich/features/home/presentation/home_profile_slot.dart';
import 'package:osetrovich/features/home/presentation/home_weekly_products_section.dart';
import 'package:osetrovich/features/notifications/domain/notifications_notifier.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationsNotifierProvider);
    final bannersAsync = ref.watch(bannersProvider);
    final currentOrderAsync = ref.watch(currentOrderProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final profileAsync =
        isAuthenticated ? ref.watch(profileNotifierProvider) : null;
    final profileSlotState = buildHomeProfileSlotUiState(
      isAuthenticated: isAuthenticated,
      profile: profileAsync ?? const AsyncData(null),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tabHome),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () => context.push('/home/notifications'),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
            const HomeWeeklyProductsSection(),
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
