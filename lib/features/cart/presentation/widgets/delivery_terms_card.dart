import 'package:flutter/material.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';

class DeliveryTermsCard extends StatelessWidget {
  const DeliveryTermsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          AppStrings.cartDeliveryTerms,
          style: const TextStyle(
            color: AppColors.dark,
            height: 1.4,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
