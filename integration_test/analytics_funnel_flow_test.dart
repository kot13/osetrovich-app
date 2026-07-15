import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:osetrovich/app.dart';
import 'package:osetrovich/core/analytics/analytics_providers.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';

import '../test/core/analytics/fake_analytics_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('analytics funnel records launch catalog cart events', (
    tester,
  ) async {
    final fakeAnalytics = FakeAnalyticsService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(MockApiClient()),
          analyticsServiceProvider.overrideWithValue(fakeAnalytics),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(fakeAnalytics.events, contains('app_launch'));

    await tester.tap(find.text(AppStrings.tabCatalog));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(fakeAnalytics.events, contains('catalog_view'));

    await tester.tap(find.text('Сёмга слабосолёная №1').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(fakeAnalytics.events, contains('product_view'));

    await tester.tap(find.textContaining('₽ +').first);
    await tester.pumpAndSettle();

    expect(fakeAnalytics.events, contains('add_to_cart'));

    await tester.tap(find.text(AppStrings.tabCart));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(fakeAnalytics.events, contains('checkout_start'));
  });
}
