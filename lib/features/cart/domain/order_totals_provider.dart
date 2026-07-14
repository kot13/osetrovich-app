import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/features/cart/domain/cart_lines_provider.dart';
import 'package:osetrovich/features/cart/domain/order_totals.dart';

final orderTotalsProvider = Provider<OrderTotals?>((ref) {
  final linesAsync = ref.watch(cartLinesProvider);
  return linesAsync.maybeWhen(
    data: (lines) {
      if (lines.isEmpty) {
        return null;
      }
      final subtotal = lines.fold<int>(
        0,
        (sum, line) => sum + line.lineTotalRub,
      );
      return calculateOrderTotals(subtotal);
    },
    orElse: () => null,
  );
});
