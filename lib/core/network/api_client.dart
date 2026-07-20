import 'package:dio/dio.dart';
import 'package:osetrovich/core/network/api_error_mapper.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';
import 'package:osetrovich/features/catalog/domain/product.dart';
import 'package:osetrovich/features/home/domain/banner.dart';
import 'package:osetrovich/features/home/domain/notification_badge.dart';
import 'package:osetrovich/features/notifications/domain/app_notification.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';
import 'package:osetrovich/features/cart/domain/order.dart';
import 'package:osetrovich/features/promotions/domain/promotion_article.dart';
import 'package:osetrovich/features/promotions/domain/promotion_type.dart';

abstract class ApiClient {
  Future<SmsRequestResponse> requestSmsCode(String phone);

  Future<TokenResponse> verifySmsCode(String phone, String code);

  Future<TokenResponse> refreshToken(String refreshToken);

  Future<void> logout();

  Future<List<CatalogCategory>> getCategories();

  Future<ProductListPage> getProducts({
    required int categoryId,
    required int offset,
    required int limit,
  });

  Future<ProductDetail> getProductById(int id);

  Future<List<Banner>> getHomeBanners();

  Future<List<ProductSummary>> getWeeklyProducts();

  Future<CurrentOrder?> getCurrentOrder();

  Future<CurrentOrder> submitOrderRating(
    String orderId,
    SubmitOrderRatingRequest request,
  );

  Future<CurrentOrder> skipOrderRating(String orderId);

  Future<NotificationBadge> getUnreadNotificationCount();

  Future<List<AppNotification>> getNotifications();

  Future<AppNotification> getNotificationById(String id);

  Future<void> markNotificationRead(String id);

  Future<void> markAllNotificationsRead();

  Future<UserProfile> getProfile();

  Future<UserProfile> updateProfile({required String name});

  Future<SmsRequestResponse> requestPhoneChange(String phone);

  Future<UserProfile> verifyPhoneChange(String phone, String code);

  Future<SmsRequestResponse> requestEmailVerification(String email);

  Future<UserProfile> verifyEmail(String email, String code);

  Future<ProfilePreferences> getProfilePreferences();

  Future<ProfilePreferences> updateProfilePreferences({
    required bool pushEnabled,
  });

  Future<Order> createOrder(CreateOrderRequest request);

  Future<List<PromotionArticleSummary>> getPromotionArticles(
    PromotionType type,
  );

  Future<PromotionArticleDetail> getPromotionArticleById(String id);
}

typedef TokenReader = Future<String?> Function();

class DioApiClient implements ApiClient {
  DioApiClient(this._dio);

  final Dio _dio;

  @override
  Future<SmsRequestResponse> requestSmsCode(String phone) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/sms/request',
        data: {'phone': phone},
      );
      return SmsRequestResponse.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<TokenResponse> verifySmsCode(String phone, String code) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/sms/verify',
        data: {'phone': phone, 'code': code},
      );
      return TokenResponse.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<TokenResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return TokenResponse.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<List<CatalogCategory>> getCategories() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/catalog/categories',
      );
      final items = response.data!['items'] as List<dynamic>;
      return items
          .map((e) => CatalogCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ProductListPage> getProducts({
    required int categoryId,
    required int offset,
    required int limit,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/catalog/products',
        queryParameters: {
          'categoryId': categoryIdToApiQuery(categoryId),
          'offset': offset,
          'limit': limit,
        },
      );
      return ProductListPage.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ProductDetail> getProductById(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/catalog/products/$id',
      );
      return ProductDetail.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<List<Banner>> getHomeBanners() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/home/banners');
      final items = response.data!['items'] as List<dynamic>;
      return items
          .map((e) => Banner.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<List<ProductSummary>> getWeeklyProducts() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/home/weekly-products',
      );
      final items = response.data!['items'] as List<dynamic>;
      return items
          .map((e) => ProductSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<CurrentOrder?> getCurrentOrder() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/orders/current');
      final orderJson = response.data!['order'];
      if (orderJson == null) {
        return null;
      }
      return CurrentOrder.fromJson(orderJson as Map<String, dynamic>);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<CurrentOrder> submitOrderRating(
    String orderId,
    SubmitOrderRatingRequest request,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/$orderId/rating',
        data: request.toJson(),
      );
      return CurrentOrder.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<CurrentOrder> skipOrderRating(String orderId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/$orderId/rating/skip',
      );
      return CurrentOrder.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<NotificationBadge> getUnreadNotificationCount() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      return NotificationBadge.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/notifications');
      final items = response.data!['items'] as List<dynamic>;
      return items
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<AppNotification> getNotificationById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/notifications/$id',
      );
      return AppNotification.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> markNotificationRead(String id) async {
    try {
      await _dio.post<void>('/notifications/$id/read');
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> markAllNotificationsRead() async {
    try {
      await _dio.post<void>('/notifications/read-all');
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<UserProfile> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/profile/me');
      return UserProfile.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<UserProfile> updateProfile({required String name}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/profile/me',
        data: {'name': name},
      );
      return UserProfile.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<SmsRequestResponse> requestPhoneChange(String phone) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/profile/phone/request',
        data: {'phone': phone},
      );
      return SmsRequestResponse.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<UserProfile> verifyPhoneChange(String phone, String code) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/profile/phone/verify',
        data: {'phone': phone, 'code': code},
      );
      return UserProfile.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<SmsRequestResponse> requestEmailVerification(String email) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/profile/email/request',
        data: {'email': email},
      );
      return SmsRequestResponse.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<UserProfile> verifyEmail(String email, String code) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/profile/email/verify',
        data: {'email': email, 'code': code},
      );
      return UserProfile.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ProfilePreferences> getProfilePreferences() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/profile/preferences',
      );
      return ProfilePreferences.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ProfilePreferences> updateProfilePreferences({
    required bool pushEnabled,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/profile/preferences',
        data: {'pushEnabled': pushEnabled},
      );
      return ProfilePreferences.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<Order> createOrder(CreateOrderRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders',
        data: request.toJson(),
      );
      return Order.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<List<PromotionArticleSummary>> getPromotionArticles(
    PromotionType type,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/promotions/articles',
        queryParameters: {'type': type.apiValue},
      );
      final items = response.data!['items'] as List<dynamic>;
      return items
          .map(
            (item) =>
                PromotionArticleSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<PromotionArticleDetail> getPromotionArticleById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/promotions/articles/$id',
      );
      return PromotionArticleDetail.fromJson(response.data!);
    } on Object catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(Object error) {
    return mapToApiException(error);
  }
}
