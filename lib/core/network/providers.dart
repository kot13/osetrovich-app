import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/api_client.dart';
import 'package:osetrovich/core/network/dio_client.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/auth/data/secure_token_storage.dart';

const useMockApi = true;

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  if (useMockApi) {
    return MockApiClient();
  }
  return createDioApiClient(tokenStorage: storage);
});
