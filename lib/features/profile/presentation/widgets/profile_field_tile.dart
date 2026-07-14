import 'package:flutter/material.dart';
import 'package:osetrovich/core/theme/app_colors.dart';

class ProfileFieldTile extends StatelessWidget {
  const ProfileFieldTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppColors.dark)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                color:
                    subtitle!.contains('Не')
                        ? Colors.orange.shade800
                        : AppColors.primary,
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
