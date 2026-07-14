import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class PromotionHtmlBody extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Html(
      data: html,
      shrinkWrap: true,
      onlyRenderTheseTags: _allowedTags,
      onLinkTap: (url, _, __) {
        if (url == null) {
          return;
        }
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
