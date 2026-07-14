import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

class ProfileRepository {
  ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UserProfile> getProfile() => _apiClient.getProfile();

  Future<UserProfile> updateName(String name) {
    return _apiClient.updateProfile(name: name);
  }

  Future<SmsRequestResponse> requestPhoneChange(String phone) {
    return _apiClient.requestPhoneChange(phone);
  }

  Future<UserProfile> verifyPhoneChange(String phone, String code) {
    return _apiClient.verifyPhoneChange(phone, code);
  }

  Future<SmsRequestResponse> requestEmailVerification(String email) {
    return _apiClient.requestEmailVerification(email);
  }

  Future<UserProfile> verifyEmail(String email, String code) {
    return _apiClient.verifyEmail(email, code);
  }

  Future<ProfilePreferences> getPreferences() {
    return _apiClient.getProfilePreferences();
  }

  Future<ProfilePreferences> updatePushEnabled(bool pushEnabled) {
    return _apiClient.updateProfilePreferences(pushEnabled: pushEnabled);
  }
}
