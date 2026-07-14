import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/loading_indicator.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/home/data/home_repository.dart';
import 'package:osetrovich/features/home/presentation/auth_prompt_banner.dart';
import 'package:osetrovich/features/home/presentation/banner_carousel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(bannersProvider);
    final badgeAsync = ref.watch(notificationBadgeProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tabHome),
        actions: [
          badgeAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.notifications_none),
                ),
            error:
                (_, __) => const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.notifications_none),
                ),
            data:
                (badge) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        onPressed: () {},
                      ),
                      if (badge.unreadCount > 0)
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
                              '${badge.unreadCount}',
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
          ),
        ],
      ),
      body: ListView(
        children: [
          bannersAsync.when(
            loading:
                () => const SizedBox(height: 180, child: LoadingIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (banners) => BannerCarousel(banners: banners),
          ),
          if (!isAuthenticated) const AuthPromptBanner(),
        ],
      ),
    );
  }
}
