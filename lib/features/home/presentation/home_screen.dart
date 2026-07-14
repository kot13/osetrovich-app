import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/loading_indicator.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/home/data/home_repository.dart';
import 'package:osetrovich/features/home/presentation/auth_prompt_banner.dart';
import 'package:osetrovich/features/home/presentation/banner_carousel.dart';
import 'package:osetrovich/features/home/presentation/home_contact_button.dart';
import 'package:osetrovich/features/notifications/domain/notifications_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationsNotifierProvider);
    final bannersAsync = ref.watch(bannersProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

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
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: bannersAsync.when(
              loading:
                  () => const SizedBox(height: 180, child: LoadingIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (banners) => BannerCarousel(banners: banners),
            ),
          ),
          const HomeContactButton(),
          if (!isAuthenticated) const AuthPromptBanner(),
        ],
      ),
    );
  }
}
