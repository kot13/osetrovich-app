import 'package:flutter/material.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Кнопка «Связаться» на главной — отдельно от ListTile в профиле.
class HomeContactButton extends StatelessWidget {
  const HomeContactButton({super.key});

  static final Uri _phoneUri = Uri.parse('tel:+78125645548');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: AppColors.dark.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => launchUrl(_phoneUri),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    AppStrings.contactUs,
                    style: TextStyle(color: AppColors.dark, fontSize: 16),
                  ),
                ),
                Icon(Icons.phone, color: AppColors.dark.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
