import 'package:osetrovich/features/cart/domain/order.dart';

class HomeOrderUiState {
  const HomeOrderUiState({
    required this.order,
    required this.showRatingPrompt,
    required this.showRepeatButton,
    required this.showContactOperator,
  });

  final CurrentOrder order;
  final bool showRatingPrompt;
  final bool showRepeatButton;
  final bool showContactOperator;
}

HomeOrderUiState buildHomeOrderUiState(CurrentOrder order) {
  final isCompleted = order.status == OrderStatus.completed;
  final ratingPending = order.ratingState == OrderRatingState.pending;
  final ratingDone =
      order.ratingState == OrderRatingState.submitted ||
      order.ratingState == OrderRatingState.skipped;

  return HomeOrderUiState(
    order: order,
    showRatingPrompt: isCompleted && ratingPending,
    showRepeatButton: isCompleted && ratingDone,
    showContactOperator: true,
  );
}
