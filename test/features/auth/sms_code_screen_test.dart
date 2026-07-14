import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/features/auth/domain/sms_auth_notifier.dart';
import 'package:osetrovich/features/auth/presentation/sms_code_screen.dart';

void main() {
  testWidgets('sms screen shows title and resend label area', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          smsAuthProvider.overrideWith(
            () => _FakeSmsAuthNotifier(
              const SmsAuthState(
                phone: '+79161234567',
                step: SmsAuthStep.smsCodeInput,
                resendSecondsRemaining: 30,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: SmsCodeScreen()),
      ),
    );

    expect(find.text(AppStrings.smsTitle), findsOneWidget);
    expect(find.text(AppStrings.smsHint), findsOneWidget);
    expect(find.textContaining('30'), findsOneWidget);
  });
}

class _FakeSmsAuthNotifier extends SmsAuthNotifier {
  _FakeSmsAuthNotifier(this._state);

  final SmsAuthState _state;

  @override
  SmsAuthState build() => _state;
}
