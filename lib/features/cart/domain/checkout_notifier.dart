import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/analytics/analytics_providers.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_profile_sync.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/data/order_repository.dart';
import 'package:osetrovich/features/cart/domain/cart_lines_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/cart/domain/order.dart';

class CheckoutState {
  const CheckoutState({
    this.isSubmitting = false,
    this.errorMessage,
    this.lastSuccessOrder,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final Order? lastSuccessOrder;

  CheckoutState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    Order? lastSuccessOrder,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CheckoutState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSuccessOrder:
          clearSuccess ? null : (lastSuccessOrder ?? this.lastSuccessOrder),
    );
  }
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  Future<Order?> submit({required String address, String? comment}) async {
    if (state.isSubmitting) {
      return null;
    }

    if (!ref.read(isAuthenticatedProvider)) {
      return null;
    }

    final session = ref.read(authSessionProvider);
    if (session != null) {
      syncMockApiProfile(ref, session);
    }

    final trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty) {
      state = state.copyWith(
        errorMessage: AppStrings.addressRequired,
        clearError: false,
      );
      return null;
    }

    final cart = ref.read(cartNotifierProvider);
    if (cart.isEmpty) {
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final trimmedComment = comment?.trim();
      final request = CreateOrderRequest(
        items: [
          for (final entry in cart.entries)
            OrderLineInput(
              productId: entry.key.toString(),
              quantity: entry.value,
            ),
        ],
        deliveryAddress: trimmedAddress,
        comment:
            trimmedComment != null && trimmedComment.isNotEmpty
                ? trimmedComment
                : null,
      );

      final order = await ref
          .read(orderRepositoryProvider)
          .createOrder(request);
      ref
          .read(analyticsServiceProvider)
          .reportOrderSuccess(orderId: order.id, orderTotalRub: order.totalRub);
      ref.read(cartNotifierProvider.notifier).clear();
      state = state.copyWith(
        isSubmitting: false,
        lastSuccessOrder: order,
        clearError: true,
      );
      return order;
    } on ApiException catch (e) {
      if (e.code == 'PRODUCT_UNAVAILABLE') {
        ref.invalidate(cartLinesProvider);
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: AppStrings.productUnavailableInCart,
        );
      } else {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage:
              e.message.isNotEmpty ? e.message : AppStrings.orderFailed,
        );
      }
      return null;
    } on Object {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: AppStrings.orderFailed,
      );
      return null;
    }
  }

  void acknowledgeSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final checkoutNotifierProvider =
    NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);
