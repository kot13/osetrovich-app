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

  testWidgets('catalog flow grid add badge detail sync', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text(AppStrings.tabCatalog));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byType(GridView), findsOneWidget);

    await tester.tap(find.text('Рыба'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final addButtons = find.byIcon(Icons.add);
    expect(addButtons, findsWidgets);

    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();
    await tester.tap(addButtons.at(1));
    await tester.pumpAndSettle();

    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.textContaining('Сёмга').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
