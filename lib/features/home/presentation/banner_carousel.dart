import 'dart:async';

import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/utils/network_image_url.dart';
import 'package:osetrovich/core/widgets/safe_cached_network_image.dart';
import 'package:osetrovich/features/home/domain/banner.dart' as home;
import 'package:osetrovich/features/home/domain/banner_link_handler.dart';

/// Соотношение сторон баннеров (800×360) — совпадает с рекомендуемым размером изображения.
const kBannerAspectRatio = 800 / 360;

const _itemHorizontalPadding = 6.0;
const _viewportFraction = 0.88;

/// Высота карусели при заданной ширине контейнера и числе баннеров.
double bannerCarouselHeightForWidth(double width, int bannerCount) {
  final viewportFraction = bannerCount <= 1 ? 1.0 : _viewportFraction;
  final slideWidth = width * viewportFraction - _itemHorizontalPadding * 2;
  return slideWidth / kBannerAspectRatio;
}

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.banners});

  final List<home.Banner> banners;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  static const _autoScrollInterval = Duration(seconds: 5);

  late final PageController _controller;
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  bool _userDragging = false;

  int get _bannerCount => widget.banners.length;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: _bannerCount <= 1 ? 1.0 : _viewportFraction,
    );
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _currentPage = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_bannerCount <= 1) {
      return;
    }

    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) => _advancePage());
  }

  Future<void> _advancePage() async {
    if (_userDragging || !_controller.hasClients || _bannerCount <= 1) {
      return;
    }

    final nextPage = (_currentPage + 1) % _bannerCount;
    await _controller.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_bannerCount <= 1) {
      return false;
    }

    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _userDragging = true;
    } else if (notification is ScrollEndNotification) {
      _userDragging = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = bannerCarouselHeightForWidth(
          constraints.maxWidth,
          widget.banners.length,
        );

        return SizedBox(
          height: height,
          width: double.infinity,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: PageView.builder(
              controller: _controller,
              padEnds: false,
              itemCount: _bannerCount,
              onPageChanged: (page) => _currentPage = page,
              itemBuilder: (context, index) {
                final banner = widget.banners[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _itemHorizontalPadding,
                  ),
                  child: AspectRatio(
                    aspectRatio: kBannerAspectRatio,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _BannerContent(
                        banner: banner,
                        bannerIndex: index,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({required this.banner, required this.bannerIndex});

  final home.Banner banner;
  final int bannerIndex;

  @override
  Widget build(BuildContext context) {
    final child =
        !isResolvableNetworkImageUrl(banner.imageUrl)
            ? Container(
              width: double.infinity,
              color: AppColors.primary.withValues(alpha: 0.15),
              child: Center(
                child: Text(
                  'Баннер ${bannerIndex + 1}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            : SafeCachedNetworkImage(
              imageUrl: banner.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder:
                  (_, __) => ColoredBox(
                    color: AppColors.background,
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
              errorWidget:
                  (_, __, ___) => ColoredBox(
                    color: AppColors.background,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.dark.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
            );

    if (banner.link.type == home.BannerLinkType.none) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => handleBannerLink(context, banner.link),
        child: child,
      ),
    );
  }
}
