import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<SmsRequestResponse> requestSms(String phone) {
    return _apiClient.requestSmsCode(phone);
  }

  Future<TokenResponse> verifySms(String phone, String code) {
    return _apiClient.verifySmsCode(phone, code);
  }

  Future<TokenResponse> refresh(String refreshToken) {
    return _apiClient.refreshToken(refreshToken);
  }

  Future<void> logout() => _apiClient.logout();
}
