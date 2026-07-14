import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';
import 'package:osetrovich/features/home/domain/banner.dart';
import 'package:osetrovich/features/home/domain/notification_badge.dart';

class MockApiClient implements ApiClient {
  static const validCode = '123456';

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
    return const NotificationBadge(unreadCount: 3);
  }

  bool _isValidPhone(String phone) => RegExp(r'^\+7\d{10}$').hasMatch(phone);
}
