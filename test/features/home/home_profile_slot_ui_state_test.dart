import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/home/domain/home_profile_slot_ui_state.dart';
import 'package:osetrovich/features/profile/domain/loyalty_status.dart';
import 'package:osetrovich/features/profile/domain/user_profile.dart';

const _profileWithStatus = UserProfile(
  id: 'u1',
  name: 'Покупатель',
  phone: '+79001111111',
  emailVerified: false,
  pushEnabled: true,
  discount: 10,
  loyaltyStatus: LoyaltyStatus.premium,
  card: '1234567890',
);

const _profileWithoutStatus = UserProfile(
  id: 'u2',
  name: 'Покупатель',
  phone: '+79003333333',
  emailVerified: false,
  pushEnabled: true,
  discount: 0,
);

void main() {
  test('guest maps to guestAuth', () {
    final state = buildHomeProfileSlotUiState(
      isAuthenticated: false,
      profile: const AsyncData(null),
    );

    expect(state.mode, HomeProfileSlotMode.guestAuth);
    expect(state.profile, isNull);
  });

  test('authenticated loading maps to loading skeleton', () {
    final state = buildHomeProfileSlotUiState(
      isAuthenticated: true,
      profile: const AsyncLoading(),
    );

    expect(state.mode, HomeProfileSlotMode.loading);
    expect(state.profile, isNull);
  });

  test('authenticated reload keeps loyalty card from previous value', () {
    const previous = AsyncData(_profileWithStatus);
    final state = buildHomeProfileSlotUiState(
      isAuthenticated: true,
      profile: const AsyncLoading<UserProfile?>().copyWithPrevious(previous),
    );

    expect(state.mode, HomeProfileSlotMode.loyalty);
    expect(state.profile, _profileWithStatus);
  });

  test('authenticated reload without loyalty keeps hidden slot', () {
    const previous = AsyncData(_profileWithoutStatus);
    final state = buildHomeProfileSlotUiState(
      isAuthenticated: true,
      profile: const AsyncLoading<UserProfile?>().copyWithPrevious(previous),
    );

    expect(state.mode, HomeProfileSlotMode.hidden);
  });

  test('authenticated error maps to hidden', () {
    final state = buildHomeProfileSlotUiState(
      isAuthenticated: true,
      profile: AsyncError(
        ApiException(code: 'NETWORK_ERROR', message: 'error'),
        StackTrace.empty,
      ),
    );

    expect(state.mode, HomeProfileSlotMode.hidden);
  });

  test('authenticated without loyalty status maps to hidden', () {
    final state = buildHomeProfileSlotUiState(
      isAuthenticated: true,
      profile: const AsyncData(_profileWithoutStatus),
    );

    expect(state.mode, HomeProfileSlotMode.hidden);
  });

  test('authenticated with loyalty status maps to loyalty', () {
    final state = buildHomeProfileSlotUiState(
      isAuthenticated: true,
      profile: const AsyncData(_profileWithStatus),
    );

    expect(state.mode, HomeProfileSlotMode.loyalty);
    expect(state.profile, _profileWithStatus);
  });
}
