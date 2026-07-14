import 'dart:async';

import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';
import 'package:osetrovich/features/profile/data/profile_repository.dart';
import 'package:osetrovich/features/profile/domain/email_validator.dart';
import 'package:osetrovich/features/profile/domain/profile_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmailVerifyState {
  const EmailVerifyState({
    this.email,
    this.resendSecondsRemaining = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final String? email;
  final int resendSecondsRemaining;
  final bool isLoading;
  final String? errorMessage;

  bool get canResend => resendSecondsRemaining <= 0 && !isLoading;

  EmailVerifyState copyWith({
    String? email,
    int? resendSecondsRemaining,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmailVerifyState(
      email: email ?? this.email,
      resendSecondsRemaining:
          resendSecondsRemaining ?? this.resendSecondsRemaining,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class EmailVerifyNotifier extends Notifier<EmailVerifyState> {
  Timer? _timer;

  @override
  EmailVerifyState build() {
    ref.onDispose(() => _timer?.cancel());
    return const EmailVerifyState();
  }

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  void updateEmail(String email) {
    state = state.copyWith(email: email.trim(), clearError: true);
  }

  Future<bool> requestCode() async {
    final email = state.email;
    if (email == null || !isValidEmail(email)) {
      state = state.copyWith(errorMessage: AppStrings.invalidEmail);
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.requestEmailVerification(email);
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
    final email = state.email;
    if (email == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _repository.verifyEmail(email, code);
      await ref.read(profileNotifierProvider.notifier).applyProfile(profile);
      _timer?.cancel();
      state = const EmailVerifyState();
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
    state = const EmailVerifyState();
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

final emailVerifyProvider =
    NotifierProvider<EmailVerifyNotifier, EmailVerifyState>(
      EmailVerifyNotifier.new,
    );
