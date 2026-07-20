import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/push/push_providers.dart';
import 'package:osetrovich/core/push/push_registration_bootstrap.dart';
import 'package:osetrovich/core/push/push_service.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockPushService extends Mock implements PushService {}

void main() {
  late _MockApiClient apiClient;
  late _MockPushService pushService;

  setUp(() {
    apiClient = _MockApiClient();
    pushService = _MockPushService();
    when(() => pushService.getTokens()).thenAnswer(
      (_) async => const {'android': 'token-1'},
    );
    when(() => pushService.listenForTokenUpdates(any())).thenReturn(null);
    when(
      () => apiClient.registerPushToken(token: any(named: 'token'), platform: any(named: 'platform')),
    ).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        pushServiceProvider.overrideWithValue(pushService),
      ],
    );
  }

  test('registers token when session appears', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    container.read(pushRegistrationBootstrapProvider);
    container.read(authSessionProvider.notifier).state = AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresAt: AuthSession.neverExpiresAt,
      phone: '+79001234567',
    );
    await Future<void>.delayed(Duration.zero);

    verify(
      () => apiClient.registerPushToken(token: 'token-1', platform: any(named: 'platform')),
    ).called(1);
  });

  test('token update listener registers new token', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    void Function(Map<String, String?>)? listener;
    when(() => pushService.listenForTokenUpdates(any())).thenAnswer((invocation) {
      listener = invocation.positionalArguments.first as void Function(Map<String, String?>);
    });

    container.read(pushRegistrationBootstrapProvider);
    container.read(authSessionProvider.notifier).state = AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresAt: AuthSession.neverExpiresAt,
      phone: '+79001234567',
    );
    await Future<void>.delayed(Duration.zero);

    listener?.call(const {'android': 'token-2'});
    await Future<void>.delayed(Duration.zero);

    verify(
      () => apiClient.registerPushToken(token: 'token-2', platform: any(named: 'platform')),
    ).called(1);
  });
}
