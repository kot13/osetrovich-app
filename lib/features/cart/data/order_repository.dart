import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/cart/domain/order.dart';

class OrderRepository {
  OrderRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Order> createOrder(CreateOrderRequest request) {
    return _apiClient.createOrder(request);
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(apiClientProvider));
});
