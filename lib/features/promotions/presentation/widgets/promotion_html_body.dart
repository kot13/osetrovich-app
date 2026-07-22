import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/deeplink/deeplink_navigation.dart';
import 'package:osetrovich/core/deeplink/deeplink_providers.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class PromotionHtmlBody extends ConsumerWidget {
  const PromotionHtmlBody({super.key, required this.html});

  final String html;

  static const _allowedTags = {
    'p',
    'br',
    'strong',
    'b',
    'em',
    'i',
    'ul',
    'ol',
    'li',
    'a',
    'body',
    'html',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolver = ref.watch(deepLinkResolverProvider);

    return Html(
      data: html,
      shrinkWrap: true,
      onlyRenderTheseTags: _allowedTags,
      onLinkTap: (url, _, __) {
        if (url == null) {
          return;
        }
        if (url.startsWith('osetrovich://')) {
          final router = GoRouter.of(context);
          DeepLinkNavigation.navigateFromUrl(
            router,
            ref.read,
            url,
            resolver: resolver,
          );
          return;
        }
        final uri = Uri.tryParse(url);
        if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      style: {
        'body': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(16),
          color: AppColors.dark,
          lineHeight: const LineHeight(1.5),
        ),
        'a': Style(
          color: AppColors.primary,
          textDecoration: TextDecoration.underline,
        ),
      },
    );
  }
}
