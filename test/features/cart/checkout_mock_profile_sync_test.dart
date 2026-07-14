import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/cart/domain/cart_notifier.dart';
import 'package:osetrovich/features/cart/domain/checkout_notifier.dart';

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}

void main() {
  test('submit seeds mock profile from session without visiting profile screen', () async {
    final mockClient = MockApiClient();
    final session = AuthSession(
      accessToken: 'mock.access.token.+79001234567',
      refreshToken: 'r',
      expiresAt: DateTime.utc(2099),
      phone: '+79001234567',
    );

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockClient),
        authSessionProvider.overrideWith(() => _FakeAuthSessionNotifier(session)),
      ],
    );
    addTearDown(container.dispose);

    container.read(cartNotifierProvider.notifier).increment('p-fish-0');

    final order = await container
        .read(checkoutNotifierProvider.notifier)
        .submit(address: 'г. Санкт-Петербург, ул. Тестовая, 1');

    expect(order, isNotNull);
    expect(container.read(cartNotifierProvider), isEmpty);
  });
}
