import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';

class ProductImageGallery extends StatelessWidget {
  const ProductImageGallery({super.key, required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.length == 1) {
      return _ProductImage(imageUrl: imageUrls.first);
    }

    return _MultiImageGallery(imageUrls: imageUrls);
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder:
            (_, __) => ColoredBox(
              color: AppColors.background,
              child: Icon(
                Icons.image_outlined,
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
            ),
        errorWidget:
            (_, __, ___) => ColoredBox(
              color: AppColors.background,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.dark.withValues(alpha: 0.4),
              ),
            ),
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
