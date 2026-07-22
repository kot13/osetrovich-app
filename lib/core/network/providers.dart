import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/dio_client.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/auth/data/secure_token_storage.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';

const useMockApi = false;

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return createDio(
    tokenStorage: storage,
    onTokensRefreshed: (tokens) async {
      await ref.read(authSessionProvider.notifier).applyRefreshedTokens(tokens);
    },
    onSessionExpired: () async {
      await ref.read(authSessionProvider.notifier).clearSession();
    },
    isSessionActive: () => ref.read(authSessionProvider) != null,
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  if (useMockApi) {
    return MockApiClient();
  }
  return DioApiClient(ref.watch(dioProvider));
});
