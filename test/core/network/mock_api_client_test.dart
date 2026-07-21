import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/profile/domain/loyalty_status.dart';

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

    test('ensureProfile seeds loyalty fields for demo phone', () async {
      final client = MockApiClient();
      client.ensureProfile('+79001111111');

      final profile = await client.getProfile();

      expect(profile.loyaltyStatus?.name, LoyaltyStatus.premium.name);
      expect(profile.discount, 10);
      expect(profile.card, '1234567890123456');
      expect(profile.lemons, 3);
      expect(profile.lemonGift, isNull);
    });

    test('ensureProfile seeds lemons for gamification demo phones', () async {
      final client = MockApiClient();

      client.ensureProfile('+79004444444');
      expect((await client.getProfile()).lemons, 0);

      client.ensureProfile('+79005555555');
      expect((await client.getProfile()).lemons, 7);

      client.ensureProfile('+79006666666');
      final giftProfile = await client.getProfile();
      expect(giftProfile.lemons, 10);
      expect(giftProfile.lemonGift, isNotNull);
    });

    test('createOrder increments lemons and applies gift at 10', () async {
      final client = MockApiClient();
      client.ensureProfile('+79004444444');

      await client.createOrder(
        const CreateOrderRequest(
          items: [OrderLineInput(id: 1000, quantity: 1)],
          deliveryAddress: 'г. Санкт-Петербург, ул. Тестовая, 1',
        ),
      );
      expect((await client.getProfile()).lemons, 1);

      client.ensureProfile('+79005555555');
      for (var i = 0; i < 3; i++) {
        await client.createOrder(
          const CreateOrderRequest(
            items: [OrderLineInput(id: 1000, quantity: 1)],
            deliveryAddress: 'г. Санкт-Петербург, ул. Тестовая, 1',
          ),
        );
      }
      expect((await client.getProfile()).lemons, 10);

      client.ensureProfile('+79006666666');
      final order = await client.createOrder(
        const CreateOrderRequest(
          items: [OrderLineInput(id: 1000, quantity: 1)],
          deliveryAddress: 'г. Санкт-Петербург, ул. Тестовая, 1',
        ),
      );
      expect(order.items.any((line) => line.isGift), isTrue);
      expect((await client.getProfile()).lemons, 1);
    });

    test('createOrder does not change lemons on validation error', () async {
      final client = MockApiClient();
      client.ensureProfile('+79004444444');

      expect(
        () => client.createOrder(
          const CreateOrderRequest(
            items: [OrderLineInput(id: 1000, quantity: 1)],
            deliveryAddress: '   ',
          ),
        ),
        throwsA(isA<ApiException>()),
      );
      expect((await client.getProfile()).lemons, 0);
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
