import 'package:dio/dio.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/auth_interceptor.dart';
import 'package:osetrovich/features/auth/data/secure_token_storage.dart';

const apiBaseUrl = 'https://api.osetrovich.ru/v1';

Dio createDio({required TokenStorage tokenStorage}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));
  return dio;
}

DioApiClient createDioApiClient({required TokenStorage tokenStorage}) {
  return DioApiClient(createDio(tokenStorage: tokenStorage));
}
