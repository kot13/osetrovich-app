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
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.banners.length,
        itemBuilder: (context, index) {
          final banner = widget.banners[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: banner.imageUrl.isEmpty
                  ? Container(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      child: Center(
                        child: Text(
                          'Баннер ${index + 1}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : Image.network(
                      banner.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.image, size: 48),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
