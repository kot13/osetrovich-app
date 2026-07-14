import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/profile/presentation/email_verify_screen.dart';

void main() {
  testWidgets('email verify screen shows email field', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const EmailVerifyScreen(),
        ),
      ),
    );

    expect(find.text(AppStrings.continueButton), findsOneWidget);
    expect(find.text(AppStrings.profileEmail), findsWidgets);
  });
}
