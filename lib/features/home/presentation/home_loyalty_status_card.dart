import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/features/home/domain/home_loyalty_status_ui_model.dart';
import 'package:osetrovich/features/home/domain/home_snackbar.dart';

class HomeLoyaltyStatusCard extends StatelessWidget {
  const HomeLoyaltyStatusCard({required this.model, super.key});

  final HomeLoyaltyStatusUiModel model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _StatusSection(model: model)),
                    if (model.hasDiscount) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: _DiscountSection(model: model),
                      ),
                    ],
                  ],
                ),
              ),
              if (model.cardNumber != null) ...[
                const SizedBox(height: 16),
                _CardNumberSection(cardNumber: model.cardNumber!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.model});

  final HomeLoyaltyStatusUiModel model;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          ),
          child: const Icon(
            Icons.workspace_premium,
            color: AppColors.accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.homeLoyaltyStatusTitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                model.statusLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              if (model.showsMaximumLevelBadge) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.accent,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.homeLoyaltyMaximumLevel,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DiscountSection extends StatelessWidget {
  const _DiscountSection({required this.model});

  final HomeLoyaltyStatusUiModel model;

  @override
  Widget build(BuildContext context) {
    final discountPercent = model.discountPercent!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.homeLoyaltyYourDiscount,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$discountPercent%',
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          model.discountAppliesToAllPurchases
              ? AppStrings.homeLoyaltyDiscountAllPurchases
              : AppStrings.homeLoyaltyDiscountExceptPromo,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _CardNumberSection extends StatelessWidget {
  const _CardNumberSection({required this.cardNumber});

  final String cardNumber;

  Future<void> _copyCardNumber(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: cardNumber));
    if (!context.mounted) {
      return;
    }
    showLoyaltyCardCopiedSnackBar(context);
  }

  @override
  Widget build(BuildContext context) {
    final formattedNumber = formatLoyaltyCardNumber(cardNumber);

    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _copyCardNumber(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.credit_card_outlined,
                color: Colors.white.withValues(alpha: 0.72),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.homeLoyaltyCardNumberLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _copyCardNumber(context),
                icon: Icon(
                  Icons.copy_outlined,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
                tooltip: AppStrings.homeLoyaltyCardCopied,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
