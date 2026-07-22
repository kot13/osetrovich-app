import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/notifications/data/notifications_repository.dart';
import 'package:osetrovich/features/notifications/domain/app_notification.dart';
import 'package:osetrovich/features/notifications/domain/notifications_notifier.dart';
import 'package:osetrovich/features/home/domain/notification_badge.dart';
import 'package:osetrovich/features/notifications/domain/unread_count_notifier.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;

  final notifications = [
    AppNotification(
      id: '1',
      title: 'A',
      body: 'Body A',
      createdAt: DateTime.utc(2026, 7, 14),
      isRead: false,
    ),
    AppNotification(
      id: '2',
      title: 'B',
      body: 'Body B',
      createdAt: DateTime.utc(2026, 7, 13),
      isRead: true,
    ),
  ];

  setUp(() {
    apiClient = _MockApiClient();
    when(
      () => apiClient.getNotifications(),
    ).thenAnswer((_) async => notifications);
    when(
      () => apiClient.getUnreadNotificationCount(),
    ).thenAnswer((_) async => const NotificationBadge(unreadCount: 1));
    when(() => apiClient.markNotificationRead(any())).thenAnswer((_) async {});
    when(() => apiClient.markAllNotificationsRead()).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
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
        notificationsRepositoryProvider.overrideWithValue(
          NotificationsRepository(apiClient),
        ),
      ],
    );
  }

  test('unreadCountProvider returns API unread count', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    await container.read(unreadCountNotifierProvider.future);

    expect(container.read(unreadCountProvider), 1);
  });

  test('markRead refreshes unread count from API', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    await container.read(notificationsNotifierProvider.future);
    when(() => apiClient.getNotifications()).thenAnswer(
      (_) async => [notifications[0].copyWith(isRead: true), notifications[1]],
    );
    when(
      () => apiClient.getUnreadNotificationCount(),
    ).thenAnswer((_) async => const NotificationBadge(unreadCount: 0));

    await container.read(notificationsNotifierProvider.notifier).markRead('1');
    await Future<void>.delayed(Duration.zero);

    expect(container.read(unreadCountProvider), 0);
  });

  test('markRead reloads list on 404', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    await container.read(notificationsNotifierProvider.future);
    when(
      () => apiClient.markNotificationRead('1'),
    ).thenThrow(ApiException(code: 'NOT_FOUND', message: 'missing'));
    when(
      () => apiClient.getNotifications(),
    ).thenAnswer((_) async => [notifications[1]]);

    await container.read(notificationsNotifierProvider.notifier).markRead('1');
    await Future<void>.delayed(Duration.zero);

    expect(container.read(notificationsNotifierProvider).value, [
      notifications[1],
    ]);
  });

  test('markRead calls API when notification is not in local list', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    await container.read(notificationsNotifierProvider.future);
    when(() => apiClient.getNotifications()).thenAnswer(
      (_) async => [notifications[0].copyWith(isRead: true), notifications[1]],
    );
    when(
      () => apiClient.getUnreadNotificationCount(),
    ).thenAnswer((_) async => const NotificationBadge(unreadCount: 0));

    await container.read(notificationsNotifierProvider.notifier).markRead('99');
    await Future<void>.delayed(Duration.zero);

    verify(() => apiClient.markNotificationRead('99')).called(1);
    expect(container.read(unreadCountProvider), 0);
  });
}

class _FakeAuthSessionNotifier extends AuthSessionNotifier {
  _FakeAuthSessionNotifier(this._session);

  final AuthSession? _session;

  @override
  AuthSession? build() => _session;
}
