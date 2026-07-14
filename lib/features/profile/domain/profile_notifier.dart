import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/profile/data/profile_repository.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

void _syncMockProfile(Ref ref, AuthSession session) {
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
  if (phone != null) {
    client.ensureProfile(phone);
  }
}

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final session = ref.watch(authSessionProvider);
    if (session == null) {
      return null;
    }
    _syncMockProfile(ref, session);
    return ref.read(profileRepositoryProvider).getProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = ref.read(authSessionProvider);
      if (session == null) return null;
      _syncMockProfile(ref, session);
      return ref.read(profileRepositoryProvider).getProfile();
    });
  }

  Future<void> updateName(String name) async {
    final updated = await ref.read(profileRepositoryProvider).updateName(name);
    state = AsyncData(updated);
  }

  Future<void> applyProfile(UserProfile profile) async {
    state = AsyncData(profile);
  }

  void clear() {
    state = const AsyncData(null);
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(ProfileNotifier.new);
