import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/theme/app_colors.dart';
import 'package:osetrovich/core/utils/price_formatter.dart';
import 'package:osetrovich/features/cart/data/order_repository.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/cart/domain/order_status_label.dart';
import 'package:osetrovich/features/catalog/data/catalog_repository.dart';
import 'package:osetrovich/features/home/domain/home_order_ui_state.dart';
import 'package:osetrovich/features/home/domain/order_rating_error.dart';
import 'package:osetrovich/features/home/domain/repeat_order.dart';
import 'package:osetrovich/features/home/presentation/order_rating_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeOrderHistorySection extends ConsumerStatefulWidget {
  const HomeOrderHistorySection({super.key, required this.order});

  final CurrentOrder order;

  @override
  ConsumerState<HomeOrderHistorySection> createState() =>
      _HomeOrderHistorySectionState();
}

class _HomeOrderHistorySectionState
    extends ConsumerState<HomeOrderHistorySection> {
  static final Uri _operatorPhoneUri = Uri.parse('tel:+78125645548');
  bool _expanded = false;
  bool _isSubmittingRating = false;
  bool _isRepeating = false;

  @override
  Widget build(BuildContext context) {
    final uiState = buildHomeOrderUiState(widget.order);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.homeOrderHistoryTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _StatusChip(label: orderStatusLabel(widget.order.status)),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Заказ ${widget.order.orderNumber}',
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.dark,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                for (final line in widget.order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            line.name,
                            style: const TextStyle(color: AppColors.dark),
                          ),
                        ),
                        Text(
                          '${line.quantity} × ${formatPriceRub(line.priceRub)}',
                          style: TextStyle(
                            color: AppColors.dark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Text(
                '${AppStrings.cartTotal}: ${formatPriceRub(widget.order.totalRub)}',
                style: const TextStyle(
                  color: AppColors.dark,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              if (uiState.showContactOperator) _OperatorButton(),
              if (uiState.showRatingPrompt) ...[
                const SizedBox(height: 12),
                Text(
                  AppStrings.homeOrderRatingPrompt,
                  style: TextStyle(
                    color: AppColors.dark.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmittingRating ? null : _onSkipRating,
                        child: const Text(AppStrings.homeOrderSkipRating),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.dark,
                        ),
                        onPressed: _isSubmittingRating ? null : _onRateOrder,
                        child: const Text(AppStrings.homeOrderRate),
                      ),
                    ),
                  ],
                ),
              ],
              if (uiState.showRepeatButton) ...[
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.dark,
                  ),
                  onPressed: _isRepeating ? null : _onRepeatOrder,
                  child:
                      _isRepeating
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text(AppStrings.homeRepeatOrder),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSkipRating() async {
    setState(() => _isSubmittingRating = true);
    try {
      await ref.read(orderRepositoryProvider).skipOrderRating(widget.order.id);
      ref.invalidate(currentOrderProvider);
    } on ApiException catch (e) {
      _showRatingError(e);
    } finally {
      if (mounted) {
        setState(() => _isSubmittingRating = false);
      }
    }
  }

  Future<void> _onRateOrder() async {
    await showOrderRatingSheet(
      context,
      onSubmit: (stars, comment) async {
        setState(() => _isSubmittingRating = true);
        try {
          await ref
              .read(orderRepositoryProvider)
              .submitOrderRating(
                widget.order.id,
                SubmitOrderRatingRequest(stars: stars, comment: comment),
              );
          ref.invalidate(currentOrderProvider);
          _showRatingThankYou();
        } on ApiException catch (e) {
          _showRatingError(e);
        } finally {
          if (mounted) {
            setState(() => _isSubmittingRating = false);
          }
        }
      },
    );
  }

  void _showRatingError(ApiException exception) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(orderRatingErrorMessage(exception))),
    );
    if (shouldRefreshOrderAfterRatingError(exception)) {
      ref.invalidate(currentOrderProvider);
    }
  }

  void _showRatingThankYou() {
    if (!mounted) {
      return;
    }
    showRatingThankYouSnackBar(context);
  }

  Future<void> _onRepeatOrder() async {
    setState(() => _isRepeating = true);
    try {
      final result = await repeatOrderToCart(
        order: widget.order,
        cart: ref.read(cartNotifierProvider.notifier),
        catalog: ref.read(catalogRepositoryProvider),
      );

      if (!mounted) {
        return;
      }

      if (result.addedLineCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.homeRepeatOrderFailed)),
        );
        return;
      }

      if (result.skippedProductIds.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.homeRepeatOrderPartial)),
        );
      }

      context.go('/cart');
    } finally {
      if (mounted) {
        setState(() => _isRepeating = false);
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OperatorButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dark.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => launchUrl(_HomeOrderHistorySectionState._operatorPhoneUri),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  AppStrings.homeContactOperator,
                  style: TextStyle(color: AppColors.dark, fontSize: 15),
                ),
              ),
              Icon(Icons.phone, color: AppColors.dark.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
