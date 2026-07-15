import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/cart/domain/order_status_label.dart';

void main() {
  group('orderStatusFromJson', () {
    test('maps pending to accepted', () {
      expect(orderStatusFromJson('pending'), OrderStatus.accepted);
    });

    test('maps all API statuses', () {
      expect(orderStatusFromJson('accepted'), OrderStatus.accepted);
      expect(orderStatusFromJson('processing'), OrderStatus.processing);
      expect(orderStatusFromJson('assembly'), OrderStatus.assembly);
      expect(orderStatusFromJson('delivery'), OrderStatus.delivery);
      expect(orderStatusFromJson('completed'), OrderStatus.completed);
    });
  });

  group('orderStatusLabel', () {
    test('returns Russian labels', () {
      expect(
        orderStatusLabel(OrderStatus.accepted),
        AppStrings.homeOrderStatusAccepted,
      );
      expect(
        orderStatusLabel(OrderStatus.processing),
        AppStrings.homeOrderStatusProcessing,
      );
      expect(
        orderStatusLabel(OrderStatus.assembly),
        AppStrings.homeOrderStatusAssembly,
      );
      expect(
        orderStatusLabel(OrderStatus.delivery),
        AppStrings.homeOrderStatusDelivery,
      );
      expect(
        orderStatusLabel(OrderStatus.completed),
        AppStrings.homeOrderStatusCompleted,
      );
    });
  });
}
