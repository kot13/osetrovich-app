import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';

/// Seeds in-memory mock profile from JWT session (needed for order/profile APIs).
void syncMockApiProfile(Ref ref, AuthSession session) {
  if (!useMockApi) {
    return;
  }
  final client = ref.read(apiClientProvider);
  if (client is! MockApiClient) {
    return;
  }
  final phone =
      session.phone.isNotEmpty
          ? session.phone
          : MockApiClient.phoneFromAccessToken(session.accessToken);
  if (phone != null && phone.isNotEmpty) {
    client.ensureProfile(phone);
  }
}
