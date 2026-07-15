import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/home/domain/home_order_ui_state.dart';

void main() {
  CurrentOrder buildOrder({
    required OrderStatus status,
    required OrderRatingState ratingState,
  }) {
    return CurrentOrder(
      id: 'ord-1',
      orderNumber: 'ORD-1',
      items: const [],
      itemsSubtotalRub: 1000,
      deliveryFeeRub: 0,
      totalRub: 1000,
      deliveryAddress: 'адрес',
      status: status,
      createdAt: DateTime.utc(2026, 7, 15),
      ratingState: ratingState,
    );
  }

  test('active order hides rating and repeat', () {
    final state = buildHomeOrderUiState(
      buildOrder(
        status: OrderStatus.delivery,
        ratingState: OrderRatingState.notApplicable,
      ),
    );
    expect(state.showRatingPrompt, isFalse);
    expect(state.showRepeatButton, isFalse);
    expect(state.showContactOperator, isTrue);
  });

  test('completed pending shows rating only', () {
    final state = buildHomeOrderUiState(
      buildOrder(
        status: OrderStatus.completed,
        ratingState: OrderRatingState.pending,
      ),
    );
    expect(state.showRatingPrompt, isTrue);
    expect(state.showRepeatButton, isFalse);
  });

  test('completed skipped shows repeat only', () {
    final state = buildHomeOrderUiState(
      buildOrder(
        status: OrderStatus.completed,
        ratingState: OrderRatingState.skipped,
      ),
    );
    expect(state.showRatingPrompt, isFalse);
    expect(state.showRepeatButton, isTrue);
  });
}
