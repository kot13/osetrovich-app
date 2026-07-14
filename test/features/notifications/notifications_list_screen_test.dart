import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/notifications/presentation/notifications_list_screen.dart';

void main() {
  testWidgets('notifications list shows items and mark-all button', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationsListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Скидка на икру'), findsOneWidget);
    expect(find.text(AppStrings.markAllRead), findsOneWidget);
  });

  testWidgets('mark all read hides floating button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationsListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.markAllRead));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.markAllRead), findsNothing);
  });
}
