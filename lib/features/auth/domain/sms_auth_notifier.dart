import 'dart:async';

import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/auth/data/auth_repository.dart';
import 'package:osetrovich/features/auth/domain/auth_session_provider.dart';
import 'package:osetrovich/features/auth/domain/phone_validator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SmsAuthStep { phoneInput, smsCodeInput }

class SmsAuthState {
  const SmsAuthState({
    this.phone,
    this.step = SmsAuthStep.phoneInput,
    this.resendSecondsRemaining = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final String? phone;
  final SmsAuthStep step;
  final int resendSecondsRemaining;
  final bool isLoading;
  final String? errorMessage;

  bool get canResend => resendSecondsRemaining <= 0 && !isLoading;

  SmsAuthState copyWith({
    String? phone,
    SmsAuthStep? step,
    int? resendSecondsRemaining,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SmsAuthState(
      phone: phone ?? this.phone,
      step: step ?? this.step,
      resendSecondsRemaining:
          resendSecondsRemaining ?? this.resendSecondsRemaining,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SmsAuthNotifier extends Notifier<SmsAuthState> {
  Timer? _timer;

  @override
  SmsAuthState build() {
    ref.onDispose(() => _timer?.cancel());
    return const SmsAuthState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone, clearError: true);
  }

  Future<bool> submitPhone() async {
    final phone = state.phone;
    if (phone == null || !isValidRussianPhone(phone)) {
      state = state.copyWith(errorMessage: AppStrings.invalidPhone);
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.requestSms(phone);
      _startResendTimer(response.retryAfterSeconds);
      state = state.copyWith(
        isLoading: false,
        step: SmsAuthStep.smsCodeInput,
        resendSecondsRemaining: response.retryAfterSeconds,
      );
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
      final tokens = await _repository.verifySms(phone, code);
      await ref
          .read(authSessionProvider.notifier)
          .setSession(tokens: tokens, phone: phone);
      _timer?.cancel();
      state = const SmsAuthState();
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
    await submitPhone();
  }

  void backToPhone() {
    _timer?.cancel();
    state = SmsAuthState(phone: state.phone);
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

final smsAuthProvider = NotifierProvider<SmsAuthNotifier, SmsAuthState>(
  SmsAuthNotifier.new,
);
