import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

void main() {
  const profile = UserProfile(
    id: 'u1',
    name: 'Покупатель',
    phone: '+79001234567',
    emailVerified: false,
    pushEnabled: true,
  );

  test('profile notifier loads profile when authenticated', () async {
    final mockClient = MockApiClient()..ensureProfile('+79001234567');

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockClient),
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionNotifier(
            AuthSession(
              accessToken: 'mock.access.token.+79001234567',
              refreshToken: 'r',
              expiresAt: DateTime.now().add(const Duration(hours: 1)),
              phone: '+79001234567',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(profileNotifierProvider.future);

    expect(result?.name, 'Покупатель');
  });

  test('profile notifier seeds mock profile from restored session token', () async {
    final mockClient = MockApiClient();

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(mockClient),
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionNotifier(
            AuthSession(
              accessToken: 'mock.access.token.+79001234567',
              refreshToken: 'r',
              expiresAt: DateTime.now().add(const Duration(hours: 1)),
              phone: '',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(profileNotifierProvider.future);

    expect(result?.phone, '+79001234567');
  });

  test('profile notifier returns null when not authenticated', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final result = await container.read(profileNotifierProvider.future);

    expect(result, isNull);
  });
}

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}
