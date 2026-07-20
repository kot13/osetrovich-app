import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/push/push_token_registration_service.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late PushTokenRegistrationService service;

  setUp(() {
    apiClient = _MockApiClient();
    service = PushTokenRegistrationService(apiClient);
  });

  test('registers token on first call', () async {
    when(
      () => apiClient.registerPushToken(token: 'abc', platform: 'android'),
    ).thenAnswer((_) async {});

    await service.registerIfNeeded(token: 'abc', platform: 'android');

    verify(
      () => apiClient.registerPushToken(token: 'abc', platform: 'android'),
    ).called(1);
  });

  test('deduplicates identical token registration', () async {
    when(
      () => apiClient.registerPushToken(token: 'abc', platform: 'android'),
    ).thenAnswer((_) async {});

    await service.registerIfNeeded(token: 'abc', platform: 'android');
    await service.registerIfNeeded(token: 'abc', platform: 'android');

    verify(
      () => apiClient.registerPushToken(token: 'abc', platform: 'android'),
    ).called(1);
  });

  test('skips empty token', () async {
    await service.registerIfNeeded(token: '', platform: 'android');

    verifyNever(() => apiClient.registerPushToken(token: any(named: 'token'), platform: any(named: 'platform')));
  });

  test('swallows validation errors', () async {
    when(
      () => apiClient.registerPushToken(token: 'abc', platform: 'android'),
    ).thenThrow(ApiException(code: 'VALIDATION_ERROR', message: 'bad'));

    await expectLater(
      service.registerIfNeeded(token: 'abc', platform: 'android'),
      completes,
    );
  });

  test('rethrows unauthorized errors', () async {
    when(
      () => apiClient.registerPushToken(token: 'abc', platform: 'android'),
    ).thenThrow(ApiException(code: 'UNAUTHORIZED', message: 'expired'));

    await expectLater(
      service.registerIfNeeded(token: 'abc', platform: 'android'),
      throwsA(isA<ApiException>()),
    );
  });
}
