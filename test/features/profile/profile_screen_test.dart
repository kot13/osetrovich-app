import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/profile/presentation/profile_screen.dart';

void main() {
  testWidgets('profile guest shows auth required', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProfileScreen(),
        ),
      ),
    );

    expect(find.text(AppStrings.profileAuthRequired), findsOneWidget);
    expect(find.text(AppStrings.signIn), findsOneWidget);
  });
}
