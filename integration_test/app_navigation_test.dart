import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:osetrovich/app.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navigate across all five tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    for (final label in [
      AppStrings.tabCatalog,
      AppStrings.tabPromotions,
      AppStrings.tabCart,
      AppStrings.tabProfile,
      AppStrings.tabHome,
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text(label), findsWidgets);
    }
  });
}
