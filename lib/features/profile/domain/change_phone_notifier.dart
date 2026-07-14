import 'dart:async';

import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/auth/domain/phone_validator.dart';
import 'package:osetrovich/features/profile/data/profile_repository.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangePhoneState {
  const ChangePhoneState({
    this.phone,
    this.resendSecondsRemaining = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final String? phone;
  final int resendSecondsRemaining;
  final bool isLoading;
  final String? errorMessage;

  bool get canResend => resendSecondsRemaining <= 0 && !isLoading;

  ChangePhoneState copyWith({
    String? phone,
    int? resendSecondsRemaining,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChangePhoneState(
      phone: phone ?? this.phone,
      resendSecondsRemaining:
          resendSecondsRemaining ?? this.resendSecondsRemaining,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ChangePhoneNotifier extends Notifier<ChangePhoneState> {
  Timer? _timer;

  @override
  ChangePhoneState build() {
    ref.onDispose(() => _timer?.cancel());
    return const ChangePhoneState();
  }

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone, clearError: true);
  }

  Future<bool> requestCode() async {
    final phone = state.phone;
    if (phone == null || !isValidRussianPhone(phone)) {
      state = state.copyWith(errorMessage: AppStrings.invalidPhone);
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.requestPhoneChange(phone);
      _startResendTimer(response.retryAfterSeconds);
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppStrings.requestFailed,
      );
      return false;
    }
  }

  Future<bool> verifyCode(String code) async {
    final phone = state.phone;
    if (phone == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _repository.verifyPhoneChange(phone, code);
      await ref.read(profileNotifierProvider.notifier).applyProfile(profile);
      _timer?.cancel();
      state = const ChangePhoneState();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppStrings.requestFailed,
      );
      return false;
    }
  }

  Future<void> resendCode() async {
    if (!state.canResend) return;
    await requestCode();
  }

  void reset() {
    _timer?.cancel();
    state = const ChangePhoneState();
  }

  void _startResendTimer(int seconds) {
    _timer?.cancel();
    state = state.copyWith(resendSecondsRemaining: seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.resendSecondsRemaining - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(resendSecondsRemaining: 0);
      } else {
        state = state.copyWith(resendSecondsRemaining: remaining);
      }
    });
  }
}

final changePhoneProvider =
    NotifierProvider<ChangePhoneNotifier, ChangePhoneState>(
      ChangePhoneNotifier.new,
    );
