import 'package:flutter/material.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/widgets/contact_block.dart';
import 'package:osetrovich/features/profile/presentation/widgets/social_links_row.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalSupportSection extends StatelessWidget {
  const LegalSupportSection({super.key});

  static final Uri privacyUri = Uri.parse(
    'https://osetrovich.ru/privacy-policy',
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ContactBlock(),
        ListTile(
          leading: const Icon(Icons.description, color: AppColors.primary),
          title: const Text(AppStrings.privacyPolicy),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap:
              () => launchUrl(privacyUri, mode: LaunchMode.externalApplication),
        ),
        const SocialLinksRow(),
      ],
    );
  }
}
