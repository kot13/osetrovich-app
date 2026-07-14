import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/notifications/data/notifications_repository.dart';
import 'package:osetrovich/features/notifications/domain/app_notification.dart';
import 'package:osetrovich/features/notifications/domain/notifications_notifier.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;

  final notifications = [
    AppNotification(
      id: 'n1',
      title: 'A',
      body: 'Body A',
      createdAt: DateTime.utc(2026, 7, 14),
      isRead: false,
    ),
    AppNotification(
      id: 'n2',
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
    when(() => apiClient.markNotificationRead(any())).thenAnswer((_) async {});
    when(() => apiClient.markAllNotificationsRead()).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        notificationsRepositoryProvider.overrideWithValue(
          NotificationsRepository(apiClient),
        ),
      ],
    );
  }

  test('unreadCountProvider returns unread notifications count', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    await container.read(notificationsNotifierProvider.future);

    expect(container.read(unreadCountProvider), 1);
  });

  test('markRead updates unread count', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    await container.read(notificationsNotifierProvider.future);
    when(() => apiClient.getNotifications()).thenAnswer(
      (_) async => [notifications[0].copyWith(isRead: true), notifications[1]],
    );

    await container.read(notificationsNotifierProvider.notifier).markRead('n1');
    await Future<void>.delayed(Duration.zero);

    expect(container.read(unreadCountProvider), 0);
  });

  test('markAllRead sets unread count to zero', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    await container.read(notificationsNotifierProvider.future);
    when(() => apiClient.getNotifications()).thenAnswer(
      (_) async => [
        notifications[0].copyWith(isRead: true),
        notifications[1].copyWith(isRead: true),
      ],
    );

    await container.read(notificationsNotifierProvider.notifier).markAllRead();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(unreadCountProvider), 0);
  });
}
