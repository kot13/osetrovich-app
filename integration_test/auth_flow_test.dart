import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:osetrovich/app.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full auth flow from profile', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text(AppStrings.tabProfile));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.signIn));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '9161234567');
    await tester.pump();

    await tester.tap(find.text(AppStrings.continueButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();

    await tester.tap(find.text(AppStrings.continueButton));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text(AppStrings.signedInPlaceholder), findsOneWidget);
  });

  // Token refresh on 401 is covered by unit tests (TokenRefreshInterceptor) because
  // integration tests use MockApiClient, which bypasses Dio interceptors.
}
