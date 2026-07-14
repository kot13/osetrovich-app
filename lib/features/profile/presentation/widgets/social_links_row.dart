import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLinksRow extends StatelessWidget {
  const SocialLinksRow({super.key});

  static final Uri vkUri = Uri.parse('https://vk.com/osetrovich');
  static final Uri okUri = Uri.parse('https://ok.ru/osetrovich');

  static const _iconColor = AppColors.dark;
  static const _iconSize = 32.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'ВКонтакте',
            onPressed:
                () => launchUrl(vkUri, mode: LaunchMode.externalApplication),
            icon: SvgPicture.asset(
              'assets/icons/vk.svg',
              width: _iconSize,
              height: _iconSize,
              colorFilter: const ColorFilter.mode(_iconColor, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            tooltip: 'Одноклассники',
            onPressed:
                () => launchUrl(okUri, mode: LaunchMode.externalApplication),
            icon: SvgPicture.asset(
              'assets/icons/ok.svg',
              width: _iconSize,
              height: _iconSize,
              colorFilter: const ColorFilter.mode(_iconColor, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }
}
