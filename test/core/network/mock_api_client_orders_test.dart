import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/cart/domain/order.dart';

void main() {
  group('MockApiClient.createOrder', () {
    late MockApiClient client;

    setUp(() {
      client = MockApiClient()..ensureProfile('+79001234567');
    });

    test('creates order with delivery fee', () async {
      final order = await client.createOrder(
        const CreateOrderRequest(
          items: [OrderLineInput(productId: '1000', quantity: 1)],
          deliveryAddress: 'г. Санкт-Петербург, Невский пр., 1',
        ),
      );

      expect(order.orderNumber, startsWith('ORD-'));
      expect(order.items, isNotEmpty);
      expect(order.deliveryAddress, contains('Санкт-Петербург'));
    });

    test('throws unauthorized without profile', () async {
      final guestClient = MockApiClient();

      expect(
        guestClient.createOrder(
          const CreateOrderRequest(
            items: [OrderLineInput(productId: '1000', quantity: 1)],
            deliveryAddress: 'адрес',
          ),
        ),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'UNAUTHORIZED'),
        ),
      );
    });

    test('throws for empty address', () async {
      expect(
        client.createOrder(
          const CreateOrderRequest(
            items: [OrderLineInput(productId: '1000', quantity: 1)],
            deliveryAddress: '   ',
          ),
        ),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'INVALID_REQUEST'),
        ),
      );
    });

    test('throws product_unavailable for unknown product', () async {
      expect(
        client.createOrder(
          const CreateOrderRequest(
            items: [OrderLineInput(productId: 'unknown-id', quantity: 1)],
            deliveryAddress: 'г. Санкт-Петербург, Невский пр., 1',
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'PRODUCT_UNAVAILABLE',
          ),
        ),
      );
    });
  });
}
