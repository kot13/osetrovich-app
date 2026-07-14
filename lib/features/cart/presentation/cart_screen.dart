import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/widgets/empty_state.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_lines_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/cart/domain/checkout_notifier.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/cart/domain/order_totals_provider.dart';
import 'package:osetrovich/features/cart/domain/pending_checkout_provider.dart';
import 'package:osetrovich/features/cart/presentation/widgets/cart_line_tile.dart';
import 'package:osetrovich/features/cart/presentation/widgets/cart_order_summary.dart';
import 'package:osetrovich/features/cart/presentation/widgets/checkout_form.dart';
import 'package:osetrovich/features/cart/presentation/widgets/delivery_terms_card.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _addressController = TextEditingController();
  final _commentController = TextEditingController();
  bool _checkoutResumeInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumePendingCheckoutAfterAuth();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckout() async {
    if (!ref.read(isAuthenticatedProvider)) {
      ref
          .read(pendingCheckoutProvider.notifier)
          .save(
            address: _addressController.text,
            comment: _commentController.text,
          );
      await context.push('/auth/phone?from=checkout');
      return;
    }

    await _submitOrder(
      address: _addressController.text,
      comment: _commentController.text,
    );
  }

  Future<void> _resumePendingCheckoutAfterAuth() async {
    if (_checkoutResumeInProgress || !mounted) {
      return;
    }

    final pending = ref.read(pendingCheckoutProvider);
    if (pending == null || !ref.read(isAuthenticatedProvider)) {
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      _addressController.text = pending.address;
    }
    if (_commentController.text.trim().isEmpty) {
      _commentController.text = pending.comment;
    }

    await _submitOrder(address: pending.address, comment: pending.comment);
  }

  Future<void> _submitOrder({
    required String address,
    required String comment,
  }) async {
    if (_checkoutResumeInProgress) {
      return;
    }

    _checkoutResumeInProgress = true;
    try {
      final order = await ref
          .read(checkoutNotifierProvider.notifier)
          .submit(address: address, comment: comment);

      if (!mounted || order == null) {
        return;
      }

      ref.read(pendingCheckoutProvider.notifier).clear();
      await _showOrderSuccessDialog(order);
    } finally {
      _checkoutResumeInProgress = false;
    }
  }

  Future<void> _showOrderSuccessDialog(Order order) async {
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(AppStrings.cartOrderSuccess),
            content: Text(
              '${AppStrings.cartOrderSuccessDetails}\n\n№ ${order.orderNumber}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );

    if (!mounted) {
      return;
    }

    ref.read(checkoutNotifierProvider.notifier).acknowledgeSuccess();
    _addressController.clear();
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      if (next && previous != true) {
        _resumePendingCheckoutAfterAuth();
      }
    });

    final distinctCount = ref.watch(cartDistinctCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabCart)),
      body:
          distinctCount == 0
              ? EmptyState(
                message: AppStrings.cartEmpty,
                actionLabel: AppStrings.goToCatalog,
                onAction: () => context.go('/catalog'),
              )
              : _FilledCartBody(
                addressController: _addressController,
                commentController: _commentController,
                onCheckout: _handleCheckout,
              ),
    );
  }
}

class _FilledCartBody extends ConsumerWidget {
  const _FilledCartBody({
    required this.addressController,
    required this.commentController,
    required this.onCheckout,
  });

  final TextEditingController addressController;
  final TextEditingController commentController;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linesAsync = ref.watch(cartLinesProvider);
    final totals = ref.watch(orderTotalsProvider);
    final checkoutState = ref.watch(checkoutNotifierProvider);

    return linesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppStrings.cartLoadFailed),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(cartLinesProvider),
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
      data: (lines) {
        if (lines.isEmpty) {
          return EmptyState(
            message: AppStrings.cartEmpty,
            actionLabel: AppStrings.goToCatalog,
            onAction: () => context.go('/catalog'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final line in lines) CartLineTile(line: line),
            if (totals != null) ...[
              const SizedBox(height: 8),
              CartOrderSummary(totals: totals),
            ],
            const SizedBox(height: 16),
            const DeliveryTermsCard(),
            const SizedBox(height: 16),
            CheckoutForm(
              addressController: addressController,
              commentController: commentController,
              onCheckout: onCheckout,
              isSubmitting: checkoutState.isSubmitting,
              errorMessage: checkoutState.errorMessage,
            ),
          ],
        );
      },
    );
  }
}
