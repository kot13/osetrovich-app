import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:osetrovich/app.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';

Future<void> _signInWithPhone(WidgetTester tester, String digits) async {
  await tester.tap(find.text(AppStrings.homeAuthButton));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).first, digits);
  await tester.pump();

  await tester.tap(find.text(AppStrings.continueButton));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).first, MockApiClient.validCode);
  await tester.pump();

  await tester.tap(find.text(AppStrings.continueButton));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest home shows auth button instead of contact', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text(AppStrings.homeAuthButton), findsOneWidget);
    expect(find.text(AppStrings.contactUs), findsNothing);
    expect(find.text(AppStrings.authPrompt), findsNothing);
  });

  testWidgets('home shows loyalty block after login with premium status', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await _signInWithPhone(tester, '9001111111');

    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Premium'), findsOneWidget);
    expect(find.text(AppStrings.homeLoyaltyYourDiscount), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('1234 5678 9012 3456'), findsOneWidget);
  });

  testWidgets('home hides loyalty slot for user without status', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await _signInWithPhone(tester, '9003333333');

    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Premium'), findsNothing);
    expect(find.text('VIP'), findsNothing);
    expect(find.text(AppStrings.homeAuthButton), findsNothing);
  });

  testWidgets('home weekly product opens detail and adds to cart', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text(AppStrings.homeWeeklyProductsTitle), findsOneWidget);

    await tester.tap(find.text('Сёмга слабосолёная №1').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text(AppStrings.tabCatalog), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('₽ +').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.textContaining('₽ +').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.tabCart));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text(AppStrings.cartCheckout), findsOneWidget);
  });

  testWidgets('home authenticated order repeat navigates to cart', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await _signInWithPhone(tester, '9003333333');

    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await tester.scrollUntilVisible(
      find.text(AppStrings.homeRepeatOrder),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text(AppStrings.homeOrderHistoryTitle), findsOneWidget);
    expect(find.text(AppStrings.homeRepeatOrder), findsOneWidget);

    await tester.tap(find.text(AppStrings.homeRepeatOrder));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text(AppStrings.cartCheckout), findsOneWidget);
  });
}
