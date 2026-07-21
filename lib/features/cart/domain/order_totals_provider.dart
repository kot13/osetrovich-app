import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_lines_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_loyalty_discount.dart';
import 'package:osetrovich/features/cart/domain/order_totals.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';

final orderTotalsProvider = Provider<OrderTotals?>((ref) {
  final linesAsync = ref.watch(cartLinesProvider);
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final profile =
      isAuthenticated ? ref.watch(profileNotifierProvider).valueOrNull : null;

  return linesAsync.maybeWhen(
    data: (lines) {
      if (lines.isEmpty) {
        return null;
      }
      return calculateOrderTotalsFromLines(
        lines: lines,
        discountPercent: profile?.discount ?? 0,
        loyaltyStatus: profile?.loyaltyStatus,
      );
    },
    orElse: () => null,
  );
});
