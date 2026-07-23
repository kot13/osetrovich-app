import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

enum HomeProfileSlotMode { guestAuth, hidden, loading, loyalty }

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

  if (profile.hasError && !profile.hasValue) {
    return const HomeProfileSlotUiState(mode: HomeProfileSlotMode.hidden);
  }

  if (profile.isLoading && !profile.hasValue) {
    return const HomeProfileSlotUiState(mode: HomeProfileSlotMode.loading);
  }

  final userProfile = profile.hasValue ? profile.requireValue : null;
  if (userProfile?.loyaltyStatus == null) {
    return const HomeProfileSlotUiState(mode: HomeProfileSlotMode.hidden);
  }

  return HomeProfileSlotUiState(
    mode: HomeProfileSlotMode.loyalty,
    profile: userProfile,
  );
}
