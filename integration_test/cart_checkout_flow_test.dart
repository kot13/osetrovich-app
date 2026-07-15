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

  testWidgets('cart checkout flow add auth order success empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text(AppStrings.tabCatalog));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.text('Рыба'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.tabCart));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text(AppStrings.cartCheckout), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'г. Санкт-Петербург, Невский пр., 1',
    );

    await tester.tap(find.text(AppStrings.cartCheckout));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '9001234567');
    await tester.tap(find.text(AppStrings.continueButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      MockApiClient.validCode,
    );
    await tester.tap(find.text(AppStrings.continueButton));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text(AppStrings.cartOrderSuccess), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.cartEmpty), findsOneWidget);
  });
}
