import 'package:dio/dio.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_error_mapper.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/auth/data/secure_token_storage.dart';

typedef OnTokensRefreshed = Future<void> Function(TokenResponse tokens);
typedef OnSessionExpired = Future<void> Function();
typedef IsSessionActive = bool Function();

class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshDio,
    required Dio retryDio,
    required OnTokensRefreshed onTokensRefreshed,
    required OnSessionExpired onSessionExpired,
    IsSessionActive? isSessionActive,
  }) : _tokenStorage = tokenStorage,
       _refreshDio = refreshDio,
       _retryDio = retryDio,
       _onTokensRefreshed = onTokensRefreshed,
       _onSessionExpired = onSessionExpired,
       _isSessionActive = isSessionActive;

  final TokenStorage _tokenStorage;
  final Dio _refreshDio;
  final Dio _retryDio;
  final OnTokensRefreshed _onTokensRefreshed;
  final OnSessionExpired _onSessionExpired;
  final IsSessionActive? _isSessionActive;

  Future<TokenResponse>? _refreshFuture;
  Future<void> _serialize = Future.value();

  static const _excludedPathSuffixes = <String>{
    '/auth/sms/request',
    '/auth/sms/verify',
    '/auth/refresh',
  };

  static bool _isExcludedPath(String path) {
    return _excludedPathSuffixes.any(path.endsWith);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    await _runSerialized(() => _handleUnauthorized(err, handler));
  }

  Future<void> _runSerialized(Future<void> Function() action) {
    final result = _serialize.then((_) => action());
    _serialize = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _handleUnauthorized(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (!_shouldAttemptRefresh(options, err.response?.statusCode)) {
      handler.next(err);
      return;
    }

    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _onSessionExpired();
      handler.reject(
        DioException(
          requestOptions: options,
          response: err.response,
          type: DioExceptionType.badResponse,
          error: ApiException(
            code: 'UNAUTHORIZED',
            message: AppStrings.sessionExpired,
          ),
        ),
      );
      return;
    }

    try {
      final tokens = await _refreshTokens();
      final isSessionActive = _isSessionActive;
      if (isSessionActive != null && !isSessionActive()) {
        handler.next(err);
        return;
      }

      final retryOptions = options.copyWith(
        headers: Map<String, dynamic>.from(options.headers)
          ..['Authorization'] = 'Bearer ${tokens.accessToken}',
      );
      final response = await _retryDio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on ApiException catch (e) {
      if (e.code == 'UNAUTHORIZED') {
        handler.reject(
          DioException(
            requestOptions: options,
            response: err.response,
            type: DioExceptionType.badResponse,
            error: e,
          ),
        );
        return;
      }
      handler.reject(
        DioException(
          requestOptions: options,
          type: _dioExceptionTypeForApi(e),
          error: e,
        ),
      );
    } catch (_) {
      handler.next(err);
    }
  }

  bool _shouldAttemptRefresh(RequestOptions options, int? statusCode) {
    if (statusCode != 401) {
      return false;
    }
    final path = options.uri.path;
    if (_isExcludedPath(path)) {
      return false;
    }
    if (options.extra['skipTokenRefresh'] == true) {
      return false;
    }
    return true;
  }

  Future<TokenResponse> _refreshTokens() {
    _refreshFuture ??= _doRefresh().whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }

  Future<TokenResponse> _doRefresh() async {
    final refresh = await _tokenStorage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      await _onSessionExpired();
      throw ApiException(
        code: 'UNAUTHORIZED',
        message: AppStrings.sessionExpired,
      );
    }

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final tokens = TokenResponse.fromJson(response.data!);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      final isSessionActive = _isSessionActive;
      if (isSessionActive == null || isSessionActive()) {
        await _onTokensRefreshed(tokens);
      }
      return tokens;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _onSessionExpired();
        throw ApiException(
          code: 'UNAUTHORIZED',
          message: AppStrings.sessionExpired,
        );
      }
      throw mapToApiException(e);
    }
  }

  DioExceptionType _dioExceptionTypeForApi(ApiException exception) {
    if (exception.code == 'NETWORK_ERROR') {
      return DioExceptionType.connectionError;
    }
    return DioExceptionType.badResponse;
  }
}
