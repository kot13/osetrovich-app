import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/auth/presentation/phone_input_screen.dart';

void main() {
  testWidgets('phone input shows title and continue button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PhoneInputScreen(),
        ),
      ),
    );

    expect(find.text(AppStrings.authTitle), findsOneWidget);
    expect(find.text(AppStrings.continueButton), findsOneWidget);
    expect(find.textContaining('+7'), findsOneWidget);
  });
}
