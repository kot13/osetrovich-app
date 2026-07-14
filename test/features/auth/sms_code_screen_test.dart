import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/auth/domain/sms_auth_notifier.dart';
import 'package:osetrovich/features/auth/presentation/sms_code_screen.dart';

void main() {
  test('canResend false while timer running', () {
    const state = SmsAuthState(resendSecondsRemaining: 30);
    expect(state.canResend, isFalse);
  });

  testWidgets('sms screen shows title and resend label area', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(theme: AppTheme.light, home: const SmsCodeScreen()),
      ),
    );

    expect(find.text(AppStrings.smsTitle), findsOneWidget);
    expect(find.text(AppStrings.continueButton), findsOneWidget);
  });
}
