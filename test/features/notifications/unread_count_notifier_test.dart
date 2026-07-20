import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/home/domain/notification_badge.dart';
import 'package:osetrovich/features/notifications/domain/unread_count_notifier.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;

  setUp(() {
    apiClient = _MockApiClient();
    when(() => apiClient.getUnreadNotificationCount()).thenAnswer(
      (_) async => const NotificationBadge(unreadCount: 5),
    );
  });

  test('loads unread count from API when authenticated', () async {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionNotifier(
            AuthSession(
              accessToken: 'a',
              refreshToken: 'r',
              expiresAt: AuthSession.neverExpiresAt,
              phone: '+79001234567',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final count = await container.read(unreadCountNotifierProvider.future);
    expect(count, 5);
  });

  test('refresh updates count after mutation', () async {
    when(() => apiClient.getUnreadNotificationCount()).thenAnswer(
      (_) async => const NotificationBadge(unreadCount: 2),
    );

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        authSessionProvider.overrideWith(
          () => _FakeAuthSessionNotifier(
            AuthSession(
              accessToken: 'a',
              refreshToken: 'r',
              expiresAt: AuthSession.neverExpiresAt,
              phone: '+79001234567',
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(unreadCountNotifierProvider.future);
    when(() => apiClient.getUnreadNotificationCount()).thenAnswer(
      (_) async => const NotificationBadge(unreadCount: 0),
    );

    await container.read(unreadCountNotifierProvider.notifier).refresh();

    expect(container.read(unreadCountProvider), 0);
  });
}

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}
