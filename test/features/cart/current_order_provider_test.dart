import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/data/order_repository.dart';
import 'package:osetrovich/features/cart/domain/order.dart';

void main() {
  test('currentOrderProvider returns null without session', () async {
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
    );
    addTearDown(container.dispose);

    expect(await container.read(currentOrderProvider.future), isNull);
  });

  test('currentOrderProvider refetches when session phone changes', () async {
    final mock = MockApiClient();
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(mock)],
    );
    addTearDown(container.dispose);

    mock.ensureProfile(MockApiClient.demoPhoneDelivery);
    container.read(authSessionProvider.notifier).state = AuthSession(
      accessToken: 'mock.access.token.${MockApiClient.demoPhoneDelivery}',
      refreshToken: 'r',
      expiresAt: DateTime.utc(2099),
      phone: MockApiClient.demoPhoneDelivery,
    );

    final deliveryOrder = await container.read(currentOrderProvider.future);
    expect(deliveryOrder?.status, OrderStatus.delivery);

    mock.ensureProfile(MockApiClient.demoPhoneRatingSkipped);
    container.read(authSessionProvider.notifier).state = AuthSession(
      accessToken: 'mock.access.token.${MockApiClient.demoPhoneRatingSkipped}',
      refreshToken: 'r',
      expiresAt: DateTime.utc(2099),
      phone: MockApiClient.demoPhoneRatingSkipped,
    );

    final repeatOrder = await container.read(currentOrderProvider.future);
    expect(repeatOrder?.status, OrderStatus.completed);
    expect(repeatOrder?.ratingState, OrderRatingState.skipped);
  });

  test('currentOrderProvider returns null after logout', () async {
    final mock = MockApiClient();
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(mock)],
    );
    addTearDown(container.dispose);

    mock.ensureProfile(MockApiClient.demoPhoneDelivery);
    container.read(authSessionProvider.notifier).state = AuthSession(
      accessToken: 'mock.access.token.${MockApiClient.demoPhoneDelivery}',
      refreshToken: 'r',
      expiresAt: DateTime.utc(2099),
      phone: MockApiClient.demoPhoneDelivery,
    );
    expect(await container.read(currentOrderProvider.future), isNotNull);

    container.read(authSessionProvider.notifier).state = null;

    expect(await container.read(currentOrderProvider.future), isNull);
  });
}
