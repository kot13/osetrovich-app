import 'package:dio/dio.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/auth_interceptor.dart';
import 'package:osetrovich/core/network/token_refresh_interceptor.dart';
import 'package:osetrovich/features/auth/data/secure_token_storage.dart';

const apiBaseUrl = 'https://trout.osetrovich.ru/v1';

Dio createDio({
  required TokenStorage tokenStorage,
  OnTokensRefreshed? onTokensRefreshed,
  OnSessionExpired? onSessionExpired,
  IsSessionActive? isSessionActive,
}) {
  final baseOptions = BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  );

  final dio = Dio(baseOptions);
  final refreshDio = Dio(baseOptions);
  final retryDio = Dio(baseOptions);

  dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));
  retryDio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));

  if (onTokensRefreshed != null && onSessionExpired != null) {
    dio.interceptors.add(
      TokenRefreshInterceptor(
        tokenStorage: tokenStorage,
        refreshDio: refreshDio,
        retryDio: retryDio,
        onTokensRefreshed: onTokensRefreshed,
        onSessionExpired: onSessionExpired,
        isSessionActive: isSessionActive,
      ),
    );
  }

  return dio;
}

DioApiClient createDioApiClient({
  required TokenStorage tokenStorage,
  OnTokensRefreshed? onTokensRefreshed,
  OnSessionExpired? onSessionExpired,
  IsSessionActive? isSessionActive,
}) {
  return DioApiClient(
    createDio(
      tokenStorage: tokenStorage,
      onTokensRefreshed: onTokensRefreshed,
      onSessionExpired: onSessionExpired,
      isSessionActive: isSessionActive,
    ),
  );
}
