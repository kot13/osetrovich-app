import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/profile/domain/change_phone_notifier.dart';
import 'package:osetrovich/features/profile/presentation/change_phone_code_screen.dart';

void main() {
  testWidgets('change phone code screen shows resend timer', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          changePhoneProvider.overrideWith(
            () => _FakeChangePhoneNotifier(
              const ChangePhoneState(
                phone: '+79001112233',
                resendSecondsRemaining: 30,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ChangePhoneCodeScreen(),
        ),
      ),
    );

    expect(find.text(AppStrings.smsTitle), findsOneWidget);
    expect(find.textContaining('30'), findsOneWidget);
  });
}

class _FakeChangePhoneNotifier extends ChangePhoneNotifier {
  _FakeChangePhoneNotifier(this._initial);

  final ChangePhoneState _initial;

  @override
  ChangePhoneState build() => _initial;
}
