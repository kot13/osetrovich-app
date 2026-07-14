import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('home shows notifications and auth prompt when logged out', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.text(AppStrings.authPrompt), findsOneWidget);
  });
}
