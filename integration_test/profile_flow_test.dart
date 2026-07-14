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

  testWidgets('profile flow login profile logout', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text(AppStrings.tabProfile));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.profileAuthRequired), findsOneWidget);

    await tester.tap(find.text(AppStrings.signIn));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '+7 (900) 123-45-67');
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.continueButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), MockApiClient.validCode);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.continueButton));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text(AppStrings.tabProfile));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.logout), findsOneWidget);
    expect(find.text('Покупатель'), findsOneWidget);

    await tester.tap(find.text(AppStrings.logout));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.profileAuthRequired), findsOneWidget);
  });
}
