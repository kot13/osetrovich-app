import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/data/order_repository.dart';
import 'package:osetrovich/features/cart/domain/order.dart';

const _phoneA = '+79001111111';
const _phoneB = '+79002222222';

Future<void> _seedOrder(MockApiClient mock, String phone) async {
  await mock.verifySmsCode(phone, MockApiClient.validCode);
  final created = await mock.createOrder(
    const CreateOrderRequest(
      items: [OrderLineInput(id: 1000, quantity: 1)],
      deliveryAddress: 'г. Санкт-Петербург, ул. Тестовая, 1',
    ),
  );
  mock.completeOrderForRating(created.id);
}

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

    await _seedOrder(mock, _phoneA);
    await mock.skipOrderRating((await mock.getCurrentOrder())!.id);

    container.read(authSessionProvider.notifier).state = AuthSession(
      accessToken: 'mock.access.token.$_phoneA',
      refreshToken: 'r',
      expiresAt: DateTime.utc(2099),
      phone: _phoneA,
    );

    final skippedOrder = await container.read(currentOrderProvider.future);
    expect(skippedOrder?.status, OrderStatus.completed);
    expect(skippedOrder?.ratingState, OrderRatingState.skipped);

    await _seedOrder(mock, _phoneB);
    container.read(authSessionProvider.notifier).state = AuthSession(
      accessToken: 'mock.access.token.$_phoneB',
      refreshToken: 'r',
      expiresAt: DateTime.utc(2099),
      phone: _phoneB,
    );

    final pendingOrder = await container.read(currentOrderProvider.future);
    expect(pendingOrder?.status, OrderStatus.completed);
    expect(pendingOrder?.ratingState, OrderRatingState.pending);
  });

  test('currentOrderProvider returns null after logout', () async {
    final mock = MockApiClient();
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(mock)],
    );
    addTearDown(container.dispose);

    await _seedOrder(mock, _phoneA);
    container.read(authSessionProvider.notifier).state = AuthSession(
      accessToken: 'mock.access.token.$_phoneA',
      refreshToken: 'r',
      expiresAt: DateTime.utc(2099),
      phone: _phoneA,
    );
    expect(await container.read(currentOrderProvider.future), isNotNull);

    container.read(authSessionProvider.notifier).state = null;

    expect(await container.read(currentOrderProvider.future), isNull);
  });
}
