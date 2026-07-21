import 'package:flutter/material.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';
import 'package:osetrovich/features/cart/domain/order_totals.dart';

class CartOrderSummary extends StatelessWidget {
  const CartOrderSummary({super.key, required this.totals});

  final OrderTotals totals;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryRow(
              label: AppStrings.cartItemsSubtotal,
              value: formatPriceRub(
                totals.hasLoyaltyDiscount
                    ? totals.itemsSubtotalBeforeDiscountRub
                    : totals.itemsSubtotalRub,
              ),
            ),
            if (totals.hasLoyaltyDiscount) ...[
              const SizedBox(height: 8),
              _SummaryRow(
                label: AppStrings.cartLoyaltyDiscount(
                  totals.loyaltyDiscountPercent!,
                ),
                value: '−${formatPriceRub(totals.loyaltyDiscountRub)}',
                valueColor: AppColors.accent,
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                label: AppStrings.cartSubtotalAfterDiscount,
                value: formatPriceRub(totals.itemsSubtotalRub),
              ),
            ],
            const SizedBox(height: 8),
            _SummaryRow(
              label: AppStrings.cartDeliveryFee,
              value:
                  totals.deliveryFeeRub == 0
                      ? AppStrings.cartDeliveryFree
                      : formatPriceRub(totals.deliveryFeeRub),
            ),
            const Divider(height: 24),
            _SummaryRow(
              label: AppStrings.cartTotal,
              value: formatPriceRub(totals.totalRub),
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: AppColors.dark,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
      fontSize: emphasized ? 16 : 14,
    );
    final valueStyle = TextStyle(
      color: valueColor ?? AppColors.dark,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
      fontSize: emphasized ? 16 : 14,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }
}
