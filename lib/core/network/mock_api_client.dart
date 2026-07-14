import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';
import 'package:osetrovich/features/home/domain/banner.dart';
import 'package:osetrovich/features/home/domain/notification_badge.dart';
import 'package:osetrovich/features/notifications/domain/app_notification.dart';

class MockApiClient implements ApiClient {
  static const validCode = '123456';

  MockApiClient() {
    _notifications = List<AppNotification>.from(_initialNotifications);
  }

  static final List<CatalogCategory> _categories = [
    const CatalogCategory(id: 'all', name: 'Все', sortOrder: 0),
    const CatalogCategory(id: 'fish', name: 'Рыба', sortOrder: 1),
    const CatalogCategory(id: 'caviar', name: 'Икра', sortOrder: 2),
    const CatalogCategory(id: 'crabs', name: 'Крабы', sortOrder: 3),
    const CatalogCategory(
      id: 'seaweed',
      name: 'Морские водоросли',
      sortOrder: 4,
    ),
    const CatalogCategory(id: 'spices', name: 'Специи', sortOrder: 5),
    const CatalogCategory(id: 'sauces', name: 'Соусы', sortOrder: 6),
    const CatalogCategory(id: 'shrimp', name: 'Креветки', sortOrder: 7),
    const CatalogCategory(id: 'mollusks', name: 'Моллюски', sortOrder: 8),
    const CatalogCategory(id: 'canned', name: 'Консервы', sortOrder: 9),
    const CatalogCategory(id: 'for_fish', name: 'Всё для рыбы', sortOrder: 10),
    const CatalogCategory(
      id: 'semi_finished',
      name: 'Полуфабрикаты',
      sortOrder: 11,
    ),
  ];

  static final List<AppNotification> _initialNotifications = [
    AppNotification(
      id: 'n1',
      title: 'Скидка на икру',
      body: 'До конца недели скидка 15% на красную икру.',
      createdAt: DateTime.utc(2026, 7, 14, 10),
      isRead: false,
    ),
    AppNotification(
      id: 'n2',
      title: 'Новая поставка крабов',
      body: 'Камчатский краб уже в каталоге.',
      createdAt: DateTime.utc(2026, 7, 13, 14, 30),
      isRead: false,
    ),
    AppNotification(
      id: 'n3',
      title: 'Ваш заказ доставлен',
      body: 'Заказ №12345 успешно доставлен.',
      createdAt: DateTime.utc(2026, 7, 12, 9, 15),
      isRead: false,
    ),
    AppNotification(
      id: 'n4',
      title: 'Акция выходного дня',
      body: 'Скидки на рыбу в субботу и воскресенье.',
      createdAt: DateTime.utc(2026, 7, 10, 8),
      isRead: true,
    ),
  ];

  late List<AppNotification> _notifications;

  @override
  Future<SmsRequestResponse> requestSmsCode(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!_isValidPhone(phone)) {
      throw ApiException(
        code: 'INVALID_PHONE',
        message: 'Некорректный номер телефона',
      );
    }
    return const SmsRequestResponse(retryAfterSeconds: 60);
  }

  @override
  Future<TokenResponse> verifySmsCode(String phone, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (code != validCode) {
      throw ApiException(code: 'INVALID_CODE', message: 'Неверный код');
    }
    return TokenResponse(
      accessToken: 'mock.access.token.$phone',
      refreshToken: 'mock.refresh.token.$phone',
      expiresIn: 3600,
      tokenType: 'Bearer',
    );
  }

  @override
  Future<TokenResponse> refreshToken(String refreshToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return TokenResponse(
      accessToken: 'mock.access.refreshed',
      refreshToken: refreshToken,
      expiresIn: 3600,
      tokenType: 'Bearer',
    );
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<List<CatalogCategory>> getCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<CatalogCategory>.from(_categories);
  }

  @override
  Future<List<Banner>> getHomeBanners() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return const [
      Banner(id: '1', imageUrl: '', sortOrder: 0),
      Banner(id: '2', imageUrl: '', sortOrder: 1),
      Banner(id: '3', imageUrl: '', sortOrder: 2),
    ];
  }

  @override
  Future<NotificationBadge> getUnreadNotificationCount() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final count = _notifications.where((n) => !n.isRead).length;
    return NotificationBadge(unreadCount: count);
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List<AppNotification>.from(_notifications);
  }

  @override
  Future<AppNotification> getNotificationById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    for (final notification in _notifications) {
      if (notification.id == id) {
        return notification;
      }
    }
    throw ApiException(code: 'NOT_FOUND', message: 'Уведомление не найдено');
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) {
      throw ApiException(code: 'NOT_FOUND', message: 'Уведомление не найдено');
    }
    _notifications[index] = _notifications[index].copyWith(isRead: true);
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _notifications = [for (final n in _notifications) n.copyWith(isRead: true)];
  }

  bool _isValidPhone(String phone) => RegExp(r'^\+7\d{10}$').hasMatch(phone);
}
