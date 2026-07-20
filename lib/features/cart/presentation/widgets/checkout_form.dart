import 'package:flutter/material.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';

class CheckoutForm extends StatelessWidget {
  const CheckoutForm({
    super.key,
    required this.addressController,
    required this.apartmentController,
    required this.commentController,
    required this.onCheckout,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final TextEditingController addressController;
  final TextEditingController apartmentController;
  final TextEditingController commentController;
  final VoidCallback onCheckout;
  final bool isSubmitting;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: AppStrings.cartAddressLabel,
            hintText: AppStrings.cartAddressHint,
            border: OutlineInputBorder(),
          ),
          minLines: 2,
          maxLines: 3,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: apartmentController,
          decoration: const InputDecoration(
            labelText: AppStrings.cartApartmentLabel,
            hintText: AppStrings.cartApartmentHint,
            border: OutlineInputBorder(),
          ),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: commentController,
          decoration: const InputDecoration(
            labelText: AppStrings.cartCommentLabel,
            hintText: AppStrings.cartCommentHint,
            border: OutlineInputBorder(),
          ),
          minLines: 2,
          maxLines: 4,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: isSubmitting ? null : onCheckout,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.dark,
              disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
            ),
            child:
                isSubmitting
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.dark,
                      ),
                    )
                    : const Text(
                      AppStrings.cartCheckout,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
          ),
        ),
      ],
    );
  }
}
