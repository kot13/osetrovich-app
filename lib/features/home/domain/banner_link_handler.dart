import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/features/home/domain/banner.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> handleBannerLink(BuildContext context, BannerLink link) async {
  switch (link.type) {
    case BannerLinkType.none:
      return;
    case BannerLinkType.external:
      final url = link.url;
      if (url == null || url.isEmpty) {
        return;
      }
      final uri = Uri.tryParse(url);
      if (uri == null) {
        _showLinkFailed(context);
        return;
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showLinkFailed(context);
      }
    case BannerLinkType.promotion:
    case BannerLinkType.news:
      final targetId = link.targetId;
      if (targetId == null || targetId.isEmpty) {
        return;
      }
      if (context.mounted) {
        context.push('/promotions/article/$targetId');
      }
    case BannerLinkType.product:
      final targetId = link.targetId;
      if (targetId == null || targetId.isEmpty) {
        return;
      }
      if (context.mounted) {
        context.push('/catalog/product/$targetId');
      }
  }
}

void _showLinkFailed(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(AppStrings.homeBannerLinkFailed)),
  );
}
