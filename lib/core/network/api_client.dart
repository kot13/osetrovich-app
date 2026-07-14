import 'package:dio/dio.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/catalog/domain/catalog_category.dart';
import 'package:osetrovich/features/home/domain/banner.dart';
import 'package:osetrovich/features/home/domain/notification_badge.dart';

abstract class ApiClient {
  Future<SmsRequestResponse> requestSmsCode(String phone);

  Future<TokenResponse> verifySmsCode(String phone, String code);

  Future<TokenResponse> refreshToken(String refreshToken);

  Future<void> logout();

  Future<List<CatalogCategory>> getCategories();

  Future<List<Banner>> getHomeBanners();

  Future<NotificationBadge> getUnreadNotificationCount();
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

  ApiException _mapError(Object error) {
    // Dio-specific mapping would go here; fallback for now.
    return ApiException(code: 'NETWORK_ERROR', message: error.toString());
  }
}
