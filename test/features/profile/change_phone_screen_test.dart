import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/profile/presentation/change_phone_screen.dart';

void main() {
  testWidgets('change phone screen shows phone field', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ChangePhoneScreen(),
        ),
      ),
    );

    expect(find.text(AppStrings.newPhoneTitle), findsOneWidget);
    expect(find.text(AppStrings.phoneHint), findsOneWidget);
  });
}
