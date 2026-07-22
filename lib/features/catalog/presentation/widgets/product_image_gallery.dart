import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/utils/network_image_url.dart';
import 'package:osetrovich/core/widgets/safe_cached_network_image.dart';

class ProductImageGallery extends StatelessWidget {
  const ProductImageGallery({super.key, required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    final resolvedUrls =
        imageUrls
            .where(isResolvableNetworkImageUrl)
            .toList(growable: false);

    if (resolvedUrls.isEmpty) {
      return const _ProductImagePlaceholder();
    }

    if (resolvedUrls.length == 1) {
      return _ProductImage(imageUrl: resolvedUrls.first);
    }

    return _MultiImageGallery(imageUrls: resolvedUrls);
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 1,
      child: ColoredBox(
        color: AppColors.background,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: AppColors.dark,
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: SafeCachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _MultiImageGallery extends StatefulWidget {
  const _MultiImageGallery({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_MultiImageGallery> createState() => _MultiImageGalleryState();
}

class _MultiImageGalleryState extends State<_MultiImageGallery> {
  late final PageController _controller;
  int _index = 0;

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
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder:
                (context, index) =>
                    _ProductImage(imageUrl: widget.imageUrls[index]),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.imageUrls.length, (index) {
            final active = index == _index;
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    active
                        ? AppColors.primary
                        : AppColors.dark.withValues(alpha: 0.2),
              ),
            );
          }),
        ),
      ],
    );
  }
}
