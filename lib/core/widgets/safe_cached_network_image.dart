import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/utils/network_image_url.dart';

/// [CachedNetworkImage] с защитой от пустых и относительных URL (без host).
class SafeCachedNetworkImage extends StatelessWidget {
  const SafeCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext context, String url)? placeholder;
  final Widget Function(BuildContext context, String url, Object error)?
  errorWidget;

  @override
  Widget build(BuildContext context) {
    if (!isResolvableNetworkImageUrl(imageUrl)) {
      return _imageFallback(Icons.image_not_supported_outlined);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder:
          placeholder ?? (_, __) => _imageFallback(Icons.image_outlined),
      errorWidget:
          errorWidget ??
          (_, __, ___) => _imageFallback(Icons.image_not_supported_outlined),
    );
  }

  Widget _imageFallback(IconData icon) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: AppColors.background,
        child: Center(
          child: Icon(
            icon,
            color: AppColors.dark.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
