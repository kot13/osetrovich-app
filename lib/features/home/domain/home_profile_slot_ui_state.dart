import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

enum HomeProfileSlotMode { guestAuth, hidden, loyalty }

class HomeProfileSlotUiState {
  const HomeProfileSlotUiState({required this.mode, this.profile});

  final HomeProfileSlotMode mode;
  final UserProfile? profile;
}

HomeProfileSlotUiState buildHomeProfileSlotUiState({
  required bool isAuthenticated,
  required AsyncValue<UserProfile?> profile,
}) {
  if (!isAuthenticated) {
    return const HomeProfileSlotUiState(mode: HomeProfileSlotMode.guestAuth);
  }

  return profile.when(
    loading:
        () => const HomeProfileSlotUiState(mode: HomeProfileSlotMode.hidden),
    error:
        (_, __) =>
            const HomeProfileSlotUiState(mode: HomeProfileSlotMode.hidden),
    data: (userProfile) {
      if (userProfile?.loyaltyStatus == null) {
        return const HomeProfileSlotUiState(mode: HomeProfileSlotMode.hidden);
      }
      return HomeProfileSlotUiState(
        mode: HomeProfileSlotMode.loyalty,
        profile: userProfile,
      );
    },
  );
}
