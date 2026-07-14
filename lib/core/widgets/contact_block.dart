import 'package:flutter/material.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactBlock extends StatelessWidget {
  const ContactBlock({super.key});

  static final Uri phoneUri = Uri.parse('tel:+78125645548');

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.phone, color: AppColors.primary),
      title: const Text(AppStrings.contactUs),
      onTap: () => launchUrl(phoneUri),
    );
  }
}
