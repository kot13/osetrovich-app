import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/data/auth_dto.dart';
import 'package:osetrovich/features/auth/data/auth_repository.dart';
import 'package:osetrovich/features/auth/data/secure_token_storage.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

class AuthSessionNotifier extends Notifier<AuthSession?> {
  @override
  AuthSession? build() => null;

  TokenStorage get _storage => ref.read(tokenStorageProvider);

  Future<void> restoreSession() async {
    final access = await _storage.readAccessToken();
    final refresh = await _storage.readRefreshToken();
    if (access == null || refresh == null) {
      state = null;
      return;
    }
    state = AuthSession(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: AuthSession.neverExpiresAt,
      phone: MockApiClient.phoneFromAccessToken(access) ?? '',
    );
  }

  Future<void> setSession({
    required TokenResponse tokens,
    required String phone,
  }) async {
    await _storage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    state = AuthSession(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: AuthSession.neverExpiresAt,
      phone: phone,
    );
  }

  Future<void> clearSession() async {
    await _storage.clear();
    state = null;
  }
}

final authSessionProvider = NotifierProvider<AuthSessionNotifier, AuthSession?>(
  AuthSessionNotifier.new,
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authSessionProvider) != null;
});
