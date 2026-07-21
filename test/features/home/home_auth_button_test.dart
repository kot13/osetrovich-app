import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/home/presentation/home_auth_button.dart';

void main() {
  testWidgets('home auth button shows label and navigates to phone auth', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: HomeAuthButton()),
        ),
        GoRoute(
          path: '/auth/phone',
          builder: (context, state) => const Scaffold(body: Text('phone-auth')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );

    expect(find.text(AppStrings.homeAuthButton), findsOneWidget);

    await tester.tap(find.text(AppStrings.homeAuthButton));
    await tester.pumpAndSettle();

    expect(find.text('phone-auth'), findsOneWidget);
  });
}
