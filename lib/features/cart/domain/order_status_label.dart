import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/features/cart/domain/order.dart';

String orderStatusLabel(OrderStatus status) {
  return switch (status) {
    OrderStatus.accepted ||
    OrderStatus.pending => AppStrings.homeOrderStatusAccepted,
    OrderStatus.processing => AppStrings.homeOrderStatusProcessing,
    OrderStatus.assembly => AppStrings.homeOrderStatusAssembly,
    OrderStatus.delivery => AppStrings.homeOrderStatusDelivery,
    OrderStatus.completed => AppStrings.homeOrderStatusCompleted,
  };
}
