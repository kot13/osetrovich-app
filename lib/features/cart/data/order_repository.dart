import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/domain/order.dart';

class OrderRepository {
  OrderRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Order> createOrder(CreateOrderRequest request) {
    return _apiClient.createOrder(request);
  }

  Future<CurrentOrder?> getCurrentOrder() {
    return _apiClient.getCurrentOrder();
  }

  Future<CurrentOrder> submitOrderRating(
    String orderId,
    SubmitOrderRatingRequest request,
  ) {
    return _apiClient.submitOrderRating(orderId, request);
  }

  Future<CurrentOrder> skipOrderRating(String orderId) {
    return _apiClient.skipOrderRating(orderId);
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiClientProvider));
});

final currentOrderProvider = FutureProvider<CurrentOrder?>((ref) async {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    return null;
  }
  return ref.watch(orderRepositoryProvider).getCurrentOrder();
});
