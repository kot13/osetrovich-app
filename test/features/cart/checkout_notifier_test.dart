import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/cart/domain/checkout_notifier.dart';
import 'package:osetrovich/features/cart/domain/order.dart';

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}

void main() {
  final session = AuthSession(
    accessToken: 'mock.access.token.+79001234567',
    refreshToken: 'r',
    expiresAt: DateTime.utc(2099),
    phone: '+79001234567',
  );

  test('submit validates empty address', () async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          MockApiClient()..ensureProfile('+79001234567'),
        ),
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionNotifier(session),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment(1000);

    final result = await container
        .read(checkoutNotifierProvider.notifier)
        .submit(address: '   ');

    expect(result, isNull);
    expect(
      container.read(checkoutNotifierProvider).errorMessage,
      AppStrings.addressRequired,
    );
    expect(container.read(cartNotifierProvider), isNotEmpty);
  });

  test('submit clears cart on success', () async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(
          MockApiClient()..ensureProfile('+79001234567'),
        ),
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionNotifier(session),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment(1000);

    final order = await container
        .read(checkoutNotifierProvider.notifier)
        .submit(address: 'г. Санкт-Петербург, ул. Тестовая, 1');

    expect(order, isNotNull);
    expect(container.read(cartNotifierProvider), isEmpty);
    expect(
      container.read(checkoutNotifierProvider).lastSuccessOrder,
      isNotNull,
    );
  });

  test('submit blocks duplicate requests while submitting', () async {
    final mockClient = _SlowMockApiClient()..ensureProfile('+79001234567');

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockClient),
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionNotifier(session),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment(1000);

    final notifier = container.read(checkoutNotifierProvider.notifier);
    final first = notifier.submit(
      address: 'г. Санкт-Петербург, ул. Тестовая, 1',
    );
    final second = notifier.submit(
      address: 'г. Санкт-Петербург, ул. Тестовая, 1',
    );

    expect(container.read(checkoutNotifierProvider).isSubmitting, isTrue);
    expect(await second, isNull);

    await first;
    expect(container.read(checkoutNotifierProvider).isSubmitting, isFalse);
  });

  test('submit preserves cart on error', () async {
    final failingClient =
        _FailingMockApiClient()..ensureProfile('+79001234567');

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(failingClient),
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionNotifier(session),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment(1000);

    final result = await container
        .read(checkoutNotifierProvider.notifier)
        .submit(address: 'г. Санкт-Петербург, ул. Тестовая, 1');

    expect(result, isNull);
    expect(container.read(cartNotifierProvider), isNotEmpty);
    expect(container.read(checkoutNotifierProvider).errorMessage, isNotNull);
  });

  test('submit passes integer product id and apartment', () async {
    final capturingClient = _CapturingMockApiClient()
      ..ensureProfile('+79001234567');

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(capturingClient),
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionNotifier(session),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment(1000);

    await container.read(checkoutNotifierProvider.notifier).submit(
          address: 'г. Санкт-Петербург, ул. Тестовая, 1',
          apartment: ' 42 ',
        );

    final request = capturingClient.lastRequest;
    expect(request, isNotNull);
    expect(request!.items.single.id, 1000);
    expect(request.apartment, '42');
    expect(request.toJson()['items'], [
      {'id': 1000, 'quantity': 1},
    ]);
  });

  test('submit omits empty apartment', () async {
    final capturingClient = _CapturingMockApiClient()
      ..ensureProfile('+79001234567');

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(capturingClient),
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionNotifier(session),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment(1000);

    await container.read(checkoutNotifierProvider.notifier).submit(
          address: 'г. Санкт-Петербург, ул. Тестовая, 1',
          apartment: '   ',
        );

    expect(capturingClient.lastRequest?.apartment, isNull);
    expect(
      capturingClient.lastRequest?.toJson().containsKey('apartment'),
      isFalse,
    );
  });
}

class _SlowMockApiClient extends MockApiClient {
  @override
  Future<Order> createOrder(CreateOrderRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return super.createOrder(request);
  }
}

class _CapturingMockApiClient extends MockApiClient {
  CreateOrderRequest? lastRequest;

  @override
  Future<Order> createOrder(CreateOrderRequest request) async {
    lastRequest = request;
    return super.createOrder(request);
  }
}

class _FailingMockApiClient extends MockApiClient {
  @override
  Future<Order> createOrder(CreateOrderRequest request) {
    throw ApiException(code: 'NETWORK_ERROR', message: AppStrings.orderFailed);
  }
}
