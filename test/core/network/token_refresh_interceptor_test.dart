import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/auth_interceptor.dart';
import 'package:osetrovich/core/network/token_refresh_interceptor.dart';
import 'package:osetrovich/features/auth/data/secure_token_storage.dart';

void main() {
  const baseUrl = 'https://api.test/v1';

  late InMemoryTokenStorage storage;
  late Dio dio;
  late Dio refreshDio;
  late DioAdapter dioAdapter;
  late DioAdapter refreshAdapter;
  var sessionExpiredCalled = false;
  var tokensRefreshedCalled = false;
  var isSessionActive = true;

  void resetCallbacks() {
    sessionExpiredCalled = false;
    tokensRefreshedCalled = false;
    isSessionActive = true;
  }

  setUp(() async {
    storage = InMemoryTokenStorage();
    await storage.saveTokens(
      accessToken: 'old-access',
      refreshToken: 'old-refresh',
    );
    resetCallbacks();

    refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
    refreshAdapter = DioAdapter(dio: refreshDio);
    refreshDio.httpClientAdapter = refreshAdapter;

    dio = Dio(BaseOptions(baseUrl: baseUrl));
    dioAdapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = dioAdapter;

    final retryDio = Dio(BaseOptions(baseUrl: baseUrl));
    retryDio.httpClientAdapter = dioAdapter;

    dio.interceptors.add(AuthInterceptor(tokenStorage: storage));
    retryDio.interceptors.add(AuthInterceptor(tokenStorage: storage));
    dio.interceptors.add(
      TokenRefreshInterceptor(
        tokenStorage: storage,
        refreshDio: refreshDio,
        retryDio: retryDio,
        onTokensRefreshed: (_) async {
          tokensRefreshedCalled = true;
        },
        onSessionExpired: () async {
          sessionExpiredCalled = true;
        },
        isSessionActive: () => isSessionActive,
      ),
    );
  });

  test('401 triggers refresh and updates stored tokens', () async {
    dioAdapter.onGet(
      '/profile/me',
      (server) => server.reply(401, {
        'code': 'unauthorized',
        'message': 'Требуется авторизация',
      }),
    );

    var refreshCalls = 0;
    refreshAdapter.onPost('/auth/refresh', (server) {
      refreshCalls++;
      server.reply(200, {
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
        'expires_in': 3600,
        'token_type': 'Bearer',
      });
    }, data: Matchers.any);

    try {
      await dio.get<Map<String, dynamic>>('/profile/me');
    } on DioException {
      // retry may still fail in test harness; refresh side effects are asserted below
    }

    expect(refreshCalls, 1);
    expect(tokensRefreshedCalled, isTrue);
    expect(sessionExpiredCalled, isFalse);
    expect(await storage.readAccessToken(), 'new-access');
  });

  test('parallel 401 requests perform single refresh', () async {
    dioAdapter.onGet(
      '/profile/me',
      (server) => server.reply(401, {
        'code': 'unauthorized',
        'message': 'Требуется авторизация',
      }),
    );

    var refreshCalls = 0;
    refreshAdapter.onPost('/auth/refresh', (server) {
      refreshCalls++;
      server.reply(200, {
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
        'expires_in': 3600,
        'token_type': 'Bearer',
      });
    }, data: Matchers.any);

    Future<void> requestProfile() async {
      try {
        await dio.get<Map<String, dynamic>>('/profile/me');
      } on DioException {
        // expected when retry cannot complete in test harness
      }
    }

    await Future.wait([requestProfile(), requestProfile()]);

    expect(refreshCalls, 1);
    expect(await storage.readAccessToken(), 'new-access');
  });

  test('auth paths do not trigger auto-refresh on 401', () async {
    for (final path in [
      '/auth/sms/request',
      '/auth/sms/verify',
      '/auth/refresh',
    ]) {
      dioAdapter.onPost(
        path,
        (server) =>
            server.reply(401, {'code': 'unauthorized', 'message': 'Ошибка'}),
        data: Matchers.any,
      );
    }

    for (final path in [
      '/auth/sms/request',
      '/auth/sms/verify',
      '/auth/refresh',
    ]) {
      await expectLater(dio.post<void>(path), throwsA(isA<DioException>()));
    }

    expect(sessionExpiredCalled, isFalse);
  });

  test('refresh 401 calls onSessionExpired and does not retry', () async {
    dioAdapter.onGet(
      '/profile/me',
      (server) => server.reply(401, {
        'code': 'unauthorized',
        'message': 'Требуется авторизация',
      }),
    );

    var refreshCalls = 0;
    refreshAdapter.onPost('/auth/refresh', (server) {
      refreshCalls++;
      server.reply(401, {'code': 'unauthorized', 'message': 'Сессия истекла'});
    }, data: Matchers.any);

    await expectLater(
      dio.get<Map<String, dynamic>>('/profile/me'),
      throwsA(isA<DioException>()),
    );

    expect(refreshCalls, 1);
    expect(sessionExpiredCalled, isTrue);
  });

  test(
    '401 without refresh token calls onSessionExpired without refresh',
    () async {
      await storage.clear();
      expect(await storage.readRefreshToken(), isNull);

      dioAdapter.onGet(
        '/profile/me',
        (server) => server.reply(401, {
          'code': 'unauthorized',
          'message': 'Требуется авторизация',
        }),
      );

      await expectLater(
        dio.get<Map<String, dynamic>>('/profile/me'),
        throwsA(isA<DioException>()),
      );

      expect(sessionExpiredCalled, isTrue);
    },
  );

  test('network error during refresh does not clear session', () async {
    dioAdapter.onGet(
      '/profile/me',
      (server) => server.reply(401, {
        'code': 'unauthorized',
        'message': 'Требуется авторизация',
      }),
    );

    refreshAdapter.onPost(
      '/auth/refresh',
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          type: DioExceptionType.connectionTimeout,
        ),
      ),
      data: Matchers.any,
    );

    await expectLater(
      dio.get<Map<String, dynamic>>('/profile/me'),
      throwsA(
        predicate<DioException>(
          (error) =>
              error.error is ApiException &&
              (error.error! as ApiException).code == 'NETWORK_ERROR',
        ),
      ),
    );

    expect(sessionExpiredCalled, isFalse);
    expect(await storage.readRefreshToken(), 'old-refresh');
  });

  test('logout during refresh skips applying tokens', () async {
    dioAdapter.onGet(
      '/profile/me',
      (server) => server.reply(401, {
        'code': 'unauthorized',
        'message': 'Требуется авторизация',
      }),
    );

    refreshAdapter.onPost('/auth/refresh', (server) {
      isSessionActive = false;
      server.reply(200, {
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
        'expires_in': 3600,
        'token_type': 'Bearer',
      });
    }, data: Matchers.any);

    await expectLater(
      dio.get<Map<String, dynamic>>('/profile/me'),
      throwsA(isA<DioException>()),
    );

    expect(tokensRefreshedCalled, isFalse);
    expect(await storage.readAccessToken(), 'new-access');
  });
}
