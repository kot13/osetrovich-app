import 'dart:async';

import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/features/home/domain/banner.dart' as home;

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.banners});

  final List<home.Banner> banners;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  static const _loopItemCount = 10000;
  static const _autoScrollInterval = Duration(seconds: 5);
  static const _viewportFraction = 0.88;

  late final PageController _controller;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    final initialPage =
        widget.banners.isEmpty
            ? 0
            : widget.banners.length * (_loopItemCount ~/ 2);
    _controller = PageController(
      initialPage: initialPage,
      viewportFraction:
          widget.banners.length <= 1 ? 1.0 : _viewportFraction,
    );
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant BannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
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
    if (widget.banners.length <= 1) {
      return;
    }

    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      if (!_controller.hasClients) {
        return;
      }
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 180,
      width: double.infinity,
      child: PageView.builder(
        controller: _controller,
        padEnds: false,
        itemCount: widget.banners.length * _loopItemCount,
        itemBuilder: (context, index) {
          final banner = widget.banners[index % widget.banners.length];
          final bannerIndex = index % widget.banners.length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _BannerContent(banner: banner, bannerIndex: bannerIndex),
            ),
          );
        },
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({required this.banner, required this.bannerIndex});

  final home.Banner banner;
  final int bannerIndex;

  @override
  Widget build(BuildContext context) {
    if (banner.imageUrl.isEmpty) {
      return Container(
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
      );
    }

    return Image.network(
      banner.imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => Container(
            color: Colors.grey.shade300,
            child: const Center(child: Icon(Icons.image, size: 48)),
          ),
    );
  }
}
