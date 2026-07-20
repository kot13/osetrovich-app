import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/cart/domain/order.dart';

void main() {
  group('MockApiClient profile', () {
    test('getProfile throws when profile is not seeded', () async {
      final client = MockApiClient();

      expect(client.getProfile(), throwsA(isA<ApiException>()));
    });

    test('ensureProfile allows getProfile after session restore', () async {
      final client = MockApiClient();
      client.ensureProfile('+79001234567');

      final profile = await client.getProfile();

      expect(profile.phone, '+79001234567');
      expect(profile.name, 'Покупатель');
    });

    test('ensureProfile does not seed demo orders', () async {
      final client = MockApiClient();
      client.ensureProfile('+79001234567');

      expect(await client.getCurrentOrder(), isNull);
    });

    test('orders are isolated per phone after createOrder', () async {
      final client = MockApiClient();
      await client.verifySmsCode('+79001111111', MockApiClient.validCode);
      final firstOrder = await client.createOrder(
        const CreateOrderRequest(
          items: [OrderLineInput(id: 1000, quantity: 1)],
          deliveryAddress: 'г. Санкт-Петербург, ул. Первая, 1',
        ),
      );
      client.completeOrderForRating(firstOrder.id);
      await client.skipOrderRating(firstOrder.id);

      await client.verifySmsCode('+79002222222', MockApiClient.validCode);
      expect(await client.getCurrentOrder(), isNull);

      final secondOrder = await client.createOrder(
        const CreateOrderRequest(
          items: [OrderLineInput(id: 1000, quantity: 1)],
          deliveryAddress: 'г. Санкт-Петербург, ул. Вторая, 2',
        ),
      );
      client.completeOrderForRating(secondOrder.id);

      final current = await client.getCurrentOrder();
      expect(current?.id, secondOrder.id);
      expect(current?.ratingState, OrderRatingState.pending);
    });

    test('phoneFromAccessToken extracts phone from mock token', () {
      expect(
        MockApiClient.phoneFromAccessToken('mock.access.token.+79001234567'),
        '+79001234567',
      );
      expect(MockApiClient.phoneFromAccessToken('other.token'), isNull);
    });
  });
}
