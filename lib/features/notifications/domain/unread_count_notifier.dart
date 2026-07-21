import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/auth_session.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';

class UnreadCountNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    ref.listen<AuthSession?>(authSessionProvider, (previous, next) {
      if (next == null) {
        state = const AsyncData(0);
      } else if (previous == null) {
        ref.invalidateSelf();
      }
    });

    if (ref.read(authSessionProvider) == null) {
      return 0;
    }

    final badge =
        await ref.read(apiClientProvider).getUnreadNotificationCount();
    return badge.unreadCount;
  }

  Future<void> refresh() async {
    if (ref.read(authSessionProvider) == null) {
      state = const AsyncData(0);
      return;
    }
    state = const AsyncLoading();
    state = AsyncData(await _loadCount());
  }

  Future<int> _loadCount() async {
    final badge =
        await ref.read(apiClientProvider).getUnreadNotificationCount();
    return badge.unreadCount;
  }
}

final unreadCountNotifierProvider =
    AsyncNotifierProvider<UnreadCountNotifier, int>(UnreadCountNotifier.new);

final unreadCountProvider = Provider<int>((ref) {
  final unreadAsync = ref.watch(unreadCountNotifierProvider);
  return unreadAsync.when(
    data: (count) => count,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(unreadCountProvider) > 0;
});
