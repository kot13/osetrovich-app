import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/profile/data/profile_repository.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

class _MockApiClient extends Mock implements ApiClient {}

void main() {
  late _MockApiClient apiClient;
  late ProfileRepository repository;

  const profile = UserProfile(
    id: 'u1',
    name: 'Покупатель',
    phone: '+79001234567',
    emailVerified: false,
    pushEnabled: true,
    discount: 0,
  );

  setUp(() {
    apiClient = _MockApiClient();
    repository = ProfileRepository(apiClient);
  });

  test('getProfile delegates to api client', () async {
    when(() => apiClient.getProfile()).thenAnswer((_) async => profile);

    final result = await repository.getProfile();

    expect(result, profile);
    verify(() => apiClient.getProfile()).called(1);
  });

  test('updateName delegates to api client', () async {
    when(
      () => apiClient.updateProfile(name: 'Новое имя'),
    ).thenAnswer((_) async => profile.copyWith(name: 'Новое имя'));

    final result = await repository.updateName('Новое имя');

    expect(result.name, 'Новое имя');
  });

  test('requestPhoneChange delegates to api client', () async {
    when(
      () => apiClient.requestPhoneChange('+79001112233'),
    ).thenAnswer((_) async => const SmsRequestResponse(retryAfterSeconds: 60));

    final result = await repository.requestPhoneChange('+79001112233');

    expect(result.retryAfterSeconds, 60);
  });

  test('verifyPhoneChange delegates to api client', () async {
    when(
      () => apiClient.verifyPhoneChange('+79001112233', '123456'),
    ).thenAnswer((_) async => profile.copyWith(phone: '+79001112233'));

    final result = await repository.verifyPhoneChange('+79001112233', '123456');

    expect(result.phone, '+79001112233');
  });

  test('requestEmailVerification delegates to api client', () async {
    when(
      () => apiClient.requestEmailVerification('user@example.com'),
    ).thenAnswer((_) async => const SmsRequestResponse(retryAfterSeconds: 60));

    await repository.requestEmailVerification('user@example.com');

    verify(
      () => apiClient.requestEmailVerification('user@example.com'),
    ).called(1);
  });

  test('verifyEmail delegates to api client', () async {
    when(() => apiClient.verifyEmail('user@example.com', '123456')).thenAnswer(
      (_) async =>
          profile.copyWith(email: 'user@example.com', emailVerified: true),
    );

    final result = await repository.verifyEmail('user@example.com', '123456');

    expect(result.emailVerified, isTrue);
    expect(result.email, 'user@example.com');
  });
}
