import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/features/notifications/data/notifications_repository.dart';
import 'package:osetrovich/features/notifications/domain/app_notification.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late NotificationsRepository repository;

  final notifications = [
    AppNotification(
      id: 'n1',
      title: 'Тест',
      body: 'Тело',
      createdAt: DateTime.utc(2026, 7, 14),
      isRead: false,
    ),
  ];

  setUp(() {
    apiClient = _MockApiClient();
    repository = NotificationsRepository(apiClient);
  });

  test('getNotifications delegates to api client', () async {
    when(
      () => apiClient.getNotifications(),
    ).thenAnswer((_) async => notifications);

    final result = await repository.getNotifications();

    expect(result, notifications);
    verify(() => apiClient.getNotifications()).called(1);
  });

  test('markRead delegates to api client', () async {
    when(() => apiClient.markNotificationRead('n1')).thenAnswer((_) async {});

    await repository.markRead('n1');

    verify(() => apiClient.markNotificationRead('n1')).called(1);
  });

  test('markAllRead delegates to api client', () async {
    when(() => apiClient.markAllNotificationsRead()).thenAnswer((_) async {});

    await repository.markAllRead();

    verify(() => apiClient.markAllNotificationsRead()).called(1);
  });
}
