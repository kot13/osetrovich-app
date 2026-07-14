import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/auth/data/auth_repository.dart';

void main() {
  late AuthRepository repository;

  setUp(() {
    repository = AuthRepository(MockApiClient());
  });

  test('requestSms succeeds for valid phone', () async {
    final response = await repository.requestSms('+79161234567');
    expect(response.retryAfterSeconds, 60);
  });

  test('verifySms succeeds with mock code', () async {
    final tokens = await repository.verifySms('+79161234567', '123456');
    expect(tokens.accessToken, isNotEmpty);
    expect(tokens.tokenType, 'Bearer');
  });

  test('verifySms fails with wrong code', () async {
    expect(
      () => repository.verifySms('+79161234567', '000000'),
      throwsA(isA<ApiException>()),
    );
  });
}
