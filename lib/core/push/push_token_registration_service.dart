import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/core/push/push_token_utils.dart';

class PushTokenRegistrationService {
  PushTokenRegistrationService(this._apiClient);

  final ApiClient _apiClient;

  String? _lastRegisteredToken;
  String? _lastRegisteredPlatform;

  Future<void> registerIfNeeded({
    required String token,
    String? platform,
  }) async {
    final resolvedPlatform = platform ?? pushPlatform;
    if (token.isEmpty) {
      return;
    }
    if (token == _lastRegisteredToken &&
        resolvedPlatform == _lastRegisteredPlatform) {
      return;
    }

    try {
      await _apiClient.registerPushToken(
        token: token,
        platform: resolvedPlatform,
      );
      _lastRegisteredToken = token;
      _lastRegisteredPlatform = resolvedPlatform;
    } on ApiException catch (error) {
      if (error.code == 'UNAUTHORIZED' || error.code == 'HTTP_401') {
        rethrow;
      }
      // 422 и прочие ошибки не блокируют приложение.
    }
  }

  Future<void> registerFromTokenMap(Map<String, String?> tokens) async {
    final token = resolvePushToken(tokens);
    if (token == null) {
      return;
    }
    await registerIfNeeded(token: token);
  }

  void clearLastRegistered() {
    _lastRegisteredToken = null;
    _lastRegisteredPlatform = null;
  }
}
