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

    test('ensureProfile switches demo orders when phone changes', () async {
      final client = MockApiClient();
      client.ensureProfile(MockApiClient.demoPhoneDelivery);
      final deliveryOrder = await client.getCurrentOrder();
      expect(deliveryOrder?.status, OrderStatus.delivery);

      client.ensureProfile(MockApiClient.demoPhoneRatingSkipped);
      final repeatOrder = await client.getCurrentOrder();
      expect(repeatOrder?.status, OrderStatus.completed);
      expect(repeatOrder?.ratingState, OrderRatingState.skipped);
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
